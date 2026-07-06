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
@export var solo_test_auto_ready := true
@export var debug_battle_seed := 1
@export_range(0.0, 5.0, 0.1) var results_duration := 0.6
@export_range(1.0, 1.2, 0.01) var button_hover_scale := 1.06
@export_range(0.05, 0.4, 0.01) var button_hover_duration := 0.12

var phase: int = Phase.SHOP
var local_ready := false
var remote_ready := false
var local_board_payload: Array[Dictionary] = []
var remote_board_payload: Array[Dictionary] = []
var _button_style: StyleBoxFlat
var _button_tween: Tween

@onready var shop_transition: ShopTransition = get_node(shop_transition_path) as ShopTransition
@onready var combat: BattleCombat = get_node(combat_path) as BattleCombat
@onready var ready_button: Button = get_node(ready_button_path) as Button
@onready var booster_rewards: BoosterPackRewards = get_node(booster_rewards_path) as BoosterPackRewards


func _ready() -> void:
	_configure_ready_button()
	_set_phase(Phase.SHOP)
	_update_ready_button()
	ready_button.pressed.connect(_on_ready_pressed)
	combat.combat_finished.connect(_on_combat_finished)
	shop_transition.shop_state_changed.connect(_on_shop_state_changed)
	booster_rewards.activity_changed.connect(_on_booster_reward_activity_changed)


func get_local_board_payload() -> Array[Dictionary]:
	return _typed_payload(local_board_payload)


func set_remote_ready(is_ready: bool, board_payload: Array = [], battle_seed: int = 0) -> void:
	remote_ready = is_ready
	remote_board_payload = _typed_payload(board_payload)
	if battle_seed > 0:
		debug_battle_seed = battle_seed
	_update_ready_button()
	_try_start_match()


func reset_ready() -> void:
	local_ready = false
	remote_ready = false
	local_board_payload.clear()
	remote_board_payload.clear()
	_update_ready_button()


func _on_ready_pressed() -> void:
	if phase != Phase.SHOP or not shop_transition.is_shop_active():
		return
	local_ready = not local_ready
	local_board_payload = combat.get_board_snapshot().to_network_payload()
	if solo_test_auto_ready:
		remote_ready = local_ready
	_update_ready_button()
	_try_start_match()


func _try_start_match() -> void:
	if phase != Phase.SHOP or not local_ready or not remote_ready:
		return
	_set_phase(Phase.READY)
	_set_phase(Phase.SYNC_BOARDS)
	await _set_inventory_locked(true)
	await shop_transition.set_shop_active(false)
	_lock_slots(true)
	_set_phase(Phase.BATTLE)
	combat.start_combat(debug_battle_seed, BattleBoardSnapshot.from_network_payload(local_board_payload))
	_update_ready_button()


func _on_combat_finished() -> void:
	if phase != Phase.BATTLE:
		return
	_set_phase(Phase.RESULTS)
	reset_ready()
	if results_duration > 0.0:
		await get_tree().create_timer(results_duration).timeout
	_set_phase(Phase.SHOP)
	_lock_slots(false)
	await shop_transition.set_shop_active(true)
	await _set_inventory_locked(false)
	_update_ready_button()


func _on_shop_state_changed(_shop_active: bool) -> void:
	_update_ready_button()


func _on_booster_reward_activity_changed(_active: bool) -> void:
	_update_ready_button()


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


func _typed_payload(payload: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in payload:
		var entry: Dictionary = value as Dictionary
		if not entry.is_empty():
			result.append(entry.duplicate(true))
	return result
