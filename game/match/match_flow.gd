class_name MatchFlow
extends Node

signal phase_changed(phase: int)

enum Phase {
	SHOP,
	READY,
	SYNC_BOARDS,
	BATTLE,
	RESULTS,
}

const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const CARD_FONT := preload("res://assets/fonts/cardfont.ttf")

@export var shop_transition_path: NodePath = ^"../ShopTransition"
@export var combat_path: NodePath = ^"../Combat"
@export var ready_button_path: NodePath = ^"../UILayer/ReadyButton"
@export var booster_rewards_path: NodePath = ^"../ShopLayer/BoosterPackRewards"
@export var network_manager_path: NodePath = ^"../NetworkManager"
@export var shop_random_path: NodePath = ^"../ShopRandom"
@export var result_popup_path: NodePath = ^"../UILayer/MatchResultPopup"
@export var initiative_popup_path: NodePath = ^"../UILayer/InitiativeRollPopup"
@export_range(0, 999, 1) var win_coin_reward := 5
@export_range(0, 999, 1) var lose_coin_reward := 8
@export var solo_test_auto_ready := true
@export var debug_battle_seed := 1
@export_range(0.0, 5.0, 0.1) var results_duration := 0.6
@export_range(1.0, 1.2, 0.01) var button_hover_scale := 1.06
@export_range(0.05, 0.4, 0.01) var button_hover_duration := 0.12

var phase: int = Phase.SHOP
var local_ready := false
var remote_ready := false
var local_board_payload: Array[BattleBoardCardSnapshot] = []
var remote_board_payload: Array[BattleBoardCardSnapshot] = []
var _battle_seed := 0
var _winner_team := -1
var _remote_player_name := "Enemy"
var _button_style: StyleBoxFlat
var _button_tween: Tween

@onready var shop_transition: ShopTransition = get_node(shop_transition_path) as ShopTransition
@onready var combat: BattleCombat = get_node(combat_path) as BattleCombat
@onready var ready_button: Button = get_node(ready_button_path) as Button
@onready var booster_rewards: BoosterPackRewards = get_node(booster_rewards_path) as BoosterPackRewards
@onready var network_manager: NetworkManager = get_node_or_null(network_manager_path) as NetworkManager
@onready var shop_random: ShopRandom = get_node_or_null(shop_random_path) as ShopRandom
@onready var result_popup: MatchResultPopup = get_node_or_null(result_popup_path) as MatchResultPopup
@onready var initiative_popup: InitiativeRollPopup = get_node_or_null(initiative_popup_path) as InitiativeRollPopup


func _ready() -> void:
	_configure_ready_button()
	_set_phase(Phase.SHOP)
	_update_ready_button()
	ready_button.pressed.connect(_on_ready_pressed)
	combat.combat_won.connect(_on_combat_won)
	combat.combat_finished.connect(_on_combat_finished)
	shop_transition.shop_state_changed.connect(_on_shop_state_changed)
	booster_rewards.activity_changed.connect(_on_booster_reward_activity_changed)
	if network_manager:
		network_manager.connected.connect(_on_network_connected)
		network_manager.remote_ready.connect(_on_network_remote_ready)
		network_manager.shop_seed_received.connect(_on_shop_seed_received)
		network_manager.player_name_received.connect(_on_player_name_received)
		network_manager.disconnected.connect(_on_network_disconnected)


func get_local_board_payload() -> Array[BattleBoardCardSnapshot]:
	return _typed_payload(local_board_payload)


func set_remote_ready(is_ready: bool, board_payload: Array = [], battle_seed: int = 0) -> void:
	remote_ready = is_ready
	remote_board_payload = _typed_payload(board_payload)
	if battle_seed > 0:
		_battle_seed = battle_seed
	_update_ready_button()
	_try_start_match()


func reset_ready() -> void:
	local_ready = false
	remote_ready = false
	local_board_payload.clear()
	remote_board_payload.clear()
	_battle_seed = 0
	_winner_team = -1
	if phase == Phase.SHOP:
		_lock_slots(false)
	_update_ready_button()


func _on_ready_pressed() -> void:
	if phase != Phase.SHOP or not shop_transition.is_shop_active():
		return
	if local_ready:
		return
	local_ready = true
	local_board_payload = combat.get_board_snapshot().to_network_payload(CardSlot.TEAM_PLAYER)
	if _has_network_peer():
		if network_manager.is_host():
			_battle_seed = _make_seed()
		if not network_manager.send_ready(local_board_payload, _battle_seed):
			local_ready = false
	elif solo_test_auto_ready:
		remote_ready = local_ready
		remote_board_payload = _typed_payload(local_board_payload)
		_battle_seed = debug_battle_seed
	_lock_slots(local_ready)
	_update_ready_button()
	_try_start_match()


func _try_start_match() -> void:
	if phase != Phase.SHOP or not local_ready or not remote_ready:
		return
	if _has_network_peer() and _battle_seed <= 0:
		return
	_set_phase(Phase.READY)
	_set_phase(Phase.SYNC_BOARDS)
	await _set_inventory_locked(true)
	await shop_transition.set_shop_active(false)
	var arena: BattleArena = get_parent() as BattleArena
	if arena:
		arena.show_remote_board(remote_board_payload)
	_lock_slots(true)
	var favored_team: int = _get_favored_team()
	if initiative_popup:
		await initiative_popup.show_roll(
			_get_local_player_name(),
			_get_remote_player_name(),
			_get_favored_name(favored_team),
			favored_team == CardSlot.TEAM_PLAYER
		)
	_set_phase(Phase.BATTLE)
	combat.start_combat(_get_battle_seed(), _build_match_snapshot(), favored_team)
	_update_ready_button()


func _on_combat_finished() -> void:
	if phase != Phase.BATTLE:
		return
	_set_phase(Phase.RESULTS)
	var winner_team: int = _winner_team
	var restore_payload: Array[BattleBoardCardSnapshot] = _typed_payload(local_board_payload)
	reset_ready()
	if result_popup and winner_team >= 0:
		await result_popup.show_winner(_get_winner_name(winner_team))
	elif results_duration > 0.0:
		await get_tree().create_timer(results_duration).timeout
	_apply_result_coins(winner_team)
	_set_phase(Phase.SHOP)
	_lock_slots(false)
	var arena: BattleArena = get_parent() as BattleArena
	if arena:
		arena.restore_player_board(restore_payload)
		arena.clear_remote_board()
	_sync_host_shop_seed()
	await shop_transition.set_shop_active(true)
	await _set_inventory_locked(false)
	_update_ready_button()


func _on_shop_state_changed(_shop_active: bool) -> void:
	_update_ready_button()


func _on_booster_reward_activity_changed(_active: bool) -> void:
	_update_ready_button()


func _on_network_connected(peer_id: int) -> void:
	if network_manager and network_manager.is_host() and peer_id == multiplayer.get_unique_id():
		return
	if network_manager and network_manager.is_host():
		_sync_host_shop_seed()
	_open_shop_after_connect()


func _on_network_remote_ready(board_payload: Array, battle_seed: int) -> void:
	set_remote_ready(true, board_payload, battle_seed)


func _on_shop_seed_received(shop_seed: int) -> void:
	_apply_shop_seed(shop_seed)


func _on_player_name_received(player_name: String) -> void:
	_remote_player_name = player_name


func _on_network_disconnected(_peer_id: int) -> void:
	var restore_payload: Array[BattleBoardCardSnapshot] = _typed_payload(local_board_payload)
	if booster_rewards:
		await booster_rewards.force_close()
	if combat:
		combat.force_stop()
	var arena: BattleArena = get_parent() as BattleArena
	if arena:
		arena.clear_remote_board()
		if not restore_payload.is_empty():
			arena.restore_player_board(restore_payload)
	_set_phase(Phase.SHOP)
	reset_ready()
	_lock_slots(false)
	await _set_inventory_locked(false)
	if shop_transition and not shop_transition.is_shop_active():
		await shop_transition.set_shop_active(true)


func _on_combat_won(winner_team: int) -> void:
	_winner_team = winner_team


func _set_phase(next_phase: int) -> void:
	if phase == next_phase:
		return
	phase = next_phase
	phase_changed.emit(phase)


func _configure_ready_button() -> void:
	ready_button.hide()
	ready_button.text = "READY"
	ready_button.pivot_offset = ready_button.size * 0.5
	ready_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ready_button.add_theme_font_override("font", CARD_FONT)
	ready_button.add_theme_font_size_override("font_size", 24)
	_button_style = StyleBoxFlat.new()
	_button_style.bg_color = LIGHT_COLOR
	_button_style.set_corner_radius_all(6)
	for state in ["normal", "hover", "pressed"]:
		ready_button.add_theme_stylebox_override(state, _button_style)
	ready_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	ready_button.mouse_entered.connect(_animate_button_hover.bind(true))
	ready_button.mouse_exited.connect(_animate_button_hover.bind(false))


func _animate_button_hover(hovered: bool) -> void:
	if _button_tween:
		_button_tween.kill()
	_button_tween = create_tween()
	_button_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_button_tween.tween_property(
		ready_button,
		"scale",
		Vector2.ONE * (button_hover_scale if hovered else 1.0),
		button_hover_duration
	)


func _update_ready_button() -> void:
	var shop_active: bool = shop_transition != null and shop_transition.is_shop_active()
	var rewards_active: bool = booster_rewards != null and booster_rewards.is_active()
	ready_button.visible = phase == Phase.SHOP and shop_active and not rewards_active
	ready_button.disabled = phase != Phase.SHOP or not shop_active or rewards_active
	ready_button.text = "WAIT" if local_ready else "READY"
	_button_style.bg_color = DARK_COLOR if local_ready else LIGHT_COLOR
	var text_color: Color = LIGHT_COLOR if local_ready else DARK_COLOR
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		ready_button.add_theme_color_override(state, text_color)


func _set_inventory_locked(locked: bool) -> void:
	var collection: CardCollection = get_tree().get_first_node_in_group("card_collections") as CardCollection
	if collection:
		await collection.set_choice_locked(locked)


func _lock_slots(locked: bool) -> void:
	var arena: BattleArena = get_parent() as BattleArena
	if arena:
		arena.set_slots_locked(locked)


func _build_match_snapshot() -> BattleBoardSnapshot:
	var snapshot := BattleBoardSnapshot.new()
	snapshot.append_payload_as_team(local_board_payload, CardSlot.TEAM_PLAYER)
	snapshot.append_payload_as_team(remote_board_payload, CardSlot.TEAM_ENEMY)
	return snapshot


func _has_network_peer() -> bool:
	return network_manager != null and network_manager.is_connected_to_peer()


func _get_battle_seed() -> int:
	if _battle_seed > 0:
		return _battle_seed
	return debug_battle_seed


func _make_seed() -> int:
	return maxi(1, int(Time.get_ticks_usec() % 2147483647))


func _sync_host_shop_seed() -> void:
	if not network_manager or not network_manager.is_host() or not network_manager.is_connected_to_peer():
		return
	var local_seed: int = _make_seed()
	var remote_seed: int = _mix_seed(local_seed)
	_apply_shop_seed(local_seed)
	network_manager.send_shop_seed(remote_seed)


func _apply_shop_seed(shop_seed: int) -> void:
	if shop_random:
		shop_random.set_seed(shop_seed)
	_refresh_shop_products()


func _mix_seed(shop_seed: int) -> int:
	return maxi(1, int((shop_seed * 1103515245 + 12345) % 2147483647))


func _refresh_shop_products() -> void:
	for node in get_tree().get_nodes_in_group("card_shop_offers"):
		var offer := node as CardShopOffer
		if offer:
			offer.reroll_offer()


func _open_shop_after_connect() -> void:
	if shop_transition and not shop_transition.is_shop_active():
		await shop_transition.set_shop_active(true)


func _get_winner_name(winner_team: int) -> String:
	if winner_team == CardSlot.TEAM_PLAYER:
		return _get_local_player_name()
	return _get_remote_player_name()


func _get_local_player_name() -> String:
	return network_manager.local_player_name if network_manager else "Player"


func _get_remote_player_name() -> String:
	if network_manager and not network_manager.remote_player_name.is_empty():
		return network_manager.remote_player_name
	return _remote_player_name


func _get_favored_team() -> int:
	if not _has_network_peer():
		return CardSlot.TEAM_PLAYER if _get_battle_seed() % 2 == 0 else CardSlot.TEAM_ENEMY
	var host_favored: bool = _get_battle_seed() % 2 == 0
	if network_manager.is_host():
		return CardSlot.TEAM_PLAYER if host_favored else CardSlot.TEAM_ENEMY
	return CardSlot.TEAM_ENEMY if host_favored else CardSlot.TEAM_PLAYER


func _get_favored_name(favored_team: int) -> String:
	return _get_local_player_name() if favored_team == CardSlot.TEAM_PLAYER else _get_remote_player_name()


func _apply_result_coins(winner_team: int) -> void:
	if winner_team < 0:
		return
	var wallet: ShopWallet = get_tree().get_first_node_in_group("shop_wallets") as ShopWallet
	if not wallet:
		return
	var reward: int = win_coin_reward if winner_team == CardSlot.TEAM_PLAYER else lose_coin_reward
	wallet.add_coins(reward)


func _typed_payload(payload: Array) -> Array[BattleBoardCardSnapshot]:
	var result: Array[BattleBoardCardSnapshot] = []
	for value in payload:
		var entry := BattleBoardSnapshot._payload_entry(value)
		if entry:
			result.append(BattleBoardCardSnapshot.new(entry.card_id, entry.team, entry.slot_index, entry.tier))
	return result
