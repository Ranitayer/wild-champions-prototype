class_name BoosterPackRewards
extends Control

signal activity_changed(active: bool)

const CARD_SCENE := preload("res://game/cards/card_template.tscn")

@export_range(0.0, 240.0, 1.0) var card_spacing := 120.0
@export_range(0.05, 0.8, 0.01) var reveal_duration := 0.24
@export_range(0.05, 0.8, 0.01) var dim_fade_duration := 0.15
@export_range(0.05, 1.0, 0.05) var reward_start_scale := 0.25
@export_range(0.0, 20.0, 0.5) var side_card_rotation_degrees := 8.0
@export_range(0.0, 20.0, 0.5) var float_distance := 6.0
@export_range(0.5, 8.0, 0.1) var float_duration := 2.4

var _dim_overlay: ColorRect
var _reward_cards: Array[CardVisual] = []
var _float_tweens: Dictionary = {}
var _float_base_positions: Dictionary = {}
var _reward_rotations: Dictionary = {}
var _hover_tweens: Dictionary = {}
var _active := false
var _hovered_card: CardVisual
var _booster_packs: Array[BoosterPack] = []
var _active_pack: BoosterPack


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	_create_dim_overlay()
	_connect_booster_packs()


func is_active() -> bool:
	return _active


func _process(_delta: float) -> void:
	var hovered_card: CardVisual = _find_hovered_reward_card()
	if hovered_card == _hovered_card:
		return
	if is_instance_valid(_hovered_card):
		_set_reward_hover(_hovered_card, false)
	_hovered_card = hovered_card
	if is_instance_valid(_hovered_card):
		_set_reward_hover(_hovered_card, true)


func _on_pack_open_requested(pack: BoosterPack) -> void:
	if _active:
		return
	var data: BoosterPackData = pack.pack_data as BoosterPackData
	var wallet: ShopWallet = _get_wallet()
	if not data or not wallet:
		return
	if wallet.is_busy():
		return
	if not wallet.can_afford(data.price):
		wallet.play_insufficient(pack)
		return
	var rewards: Array[CardData] = data.pick_rewards(data.reward_count, _get_random_generator())
	if rewards.size() != data.reward_count:
		return
	_set_active(true)
	pack.set_payment_pending(true)
	var purchase_succeeded: bool = await wallet.try_spend(
		data.price,
		pack.get_price_stat(),
		pack
	)
	if not purchase_succeeded:
		_set_active(false)
		pack.set_payment_pending(false)
		return
	_active_pack = pack
	await _set_collection_locked(true)
	_dim_overlay.show()
	_dim_overlay.color.a = 0.0
	var pack_center: Vector2 = pack.global_position + pack.size * 0.5
	_close_other_products(pack)
	await pack.play_open_pack(_dim_overlay)
	_show_rewards(rewards, pack_center)


func _show_rewards(rewards: Array[CardData], spawn_center: Vector2) -> void:
	_clear_rewards()
	var targets: Array[Vector2] = _get_reward_positions(rewards.size())
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for index in range(rewards.size()):
		var card: CardVisual = _create_reward_card(rewards[index] as CardData, spawn_center)
		var reward_rotation: float = _get_reward_rotation(index, rewards.size())
		_reward_cards.append(card)
		_reward_rotations[card.get_instance_id()] = reward_rotation
		tween.tween_property(card, "global_position", targets[index], reveal_duration)
		tween.tween_property(card.card_surface, "rotation_degrees", reward_rotation, reveal_duration)
		tween.tween_property(card, "scale", Vector2.ONE, reveal_duration)
	await tween.finished
	for card in _reward_cards:
		if is_instance_valid(card):
			_start_card_float(card)
	set_process(true)


func _get_reward_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var gap_count: int = maxi(0, count - 1)
	var row_width: float = CardMetrics.SIZE.x * float(count) + card_spacing * float(gap_count)
	var start_x: float = viewport_rect.position.x + (viewport_rect.size.x - row_width) * 0.5
	var top_y: float = viewport_rect.position.y + (viewport_rect.size.y - CardMetrics.SIZE.y) * 0.5
	for index in range(count):
		var x_position: float = start_x + float(index) * (CardMetrics.SIZE.x + card_spacing)
		positions.append(Vector2(x_position, top_y))
	return positions


func _create_reward_card(data: CardData, spawn_center: Vector2) -> CardVisual:
	var card: CardVisual = CARD_SCENE.instantiate() as CardVisual
	card.card_data = data
	card.scale = Vector2.ONE * reward_start_scale
	card.global_position = spawn_center - CardMetrics.SIZE * 0.5
	card.rotation_degrees = 0.0
	card.z_index = 100
	add_child(card)
	card.pivot_offset = CardMetrics.SIZE * 0.5
	card.set_card_tier(1)
	card.drag_started.connect(_on_reward_drag_started, CONNECT_ONE_SHOT)
	return card


func _on_reward_drag_started(card: CardVisual) -> void:
	_stop_card_float(card)
	_clear_reward_state(card)
	card.reparent(get_tree().current_scene, true)
	await _close_rewards(card)
	_reopen_products()


func _close_rewards(keep_card: CardVisual = null) -> void:
	for card in _reward_cards:
		if card == keep_card:
			continue
		_stop_card_float(card)
		_clear_reward_state(card)
		if is_instance_valid(card):
			card.queue_free()
	_reward_cards.clear()
	_hovered_card = null
	set_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(_dim_overlay, "color:a", 0.0, dim_fade_duration)
	await tween.finished
	_dim_overlay.hide()
	_set_active(false)
	_active_pack = null
	_set_collection_locked(false)


func _clear_rewards() -> void:
	for card in _reward_cards:
		_stop_card_float(card)
		_clear_reward_state(card)
		if is_instance_valid(card):
			card.queue_free()
	_reward_cards.clear()
	_hovered_card = null
	set_process(false)


func _start_card_float(card: CardVisual) -> void:
	if not is_instance_valid(card) or not _reward_cards.has(card):
		return
	var instance_id: int = card.get_instance_id()
	if _float_tweens.has(instance_id):
		return
	var base_position: Vector2 = card.global_position
	_float_base_positions[instance_id] = base_position
	var tween: Tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "global_position:y", base_position.y - float_distance, float_duration * 0.5)
	tween.tween_property(card, "global_position:y", base_position.y + float_distance, float_duration * 0.5)
	tween.tween_property(card, "global_position:y", base_position.y, float_duration * 0.5)
	_float_tweens[instance_id] = tween


func _stop_card_float(card: CardVisual) -> void:
	var instance_id: int = card.get_instance_id()
	var tween: Tween = _float_tweens.get(instance_id) as Tween
	if tween and tween.is_valid():
		tween.kill()
	_float_tweens.erase(instance_id)
	if is_instance_valid(card) and _float_base_positions.has(instance_id):
		card.global_position = _float_base_positions[instance_id]
	_float_base_positions.erase(instance_id)


func _set_reward_hover(card: CardVisual, hovered: bool) -> void:
	if not is_instance_valid(card) or not _reward_cards.has(card):
		return
	_stop_card_float(card)
	var instance_id: int = card.get_instance_id()
	var old_tween: Tween = _hover_tweens.get(instance_id) as Tween
	if old_tween and old_tween.is_valid():
		old_tween.kill()
	if not hovered:
		await get_tree().process_frame
		if not is_instance_valid(card) or _hovered_card == card:
			return
	var target_rotation: float = 0.0 if hovered else float(_reward_rotations.get(instance_id, 0.0))
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card.card_surface, "rotation_degrees", target_rotation, 0.14)
	_hover_tweens[instance_id] = tween
	if not hovered:
		await tween.finished
		_start_card_float(card)


func _clear_reward_state(card: CardVisual) -> void:
	var instance_id: int = card.get_instance_id()
	var old_tween: Tween = _hover_tweens.get(instance_id) as Tween
	if old_tween and old_tween.is_valid():
		old_tween.kill()
	_hover_tweens.erase(instance_id)
	_reward_rotations.erase(instance_id)
	_float_base_positions.erase(instance_id)


func _get_reward_rotation(index: int, count: int) -> float:
	var middle_index: int = floori(float(count) * 0.5)
	if count < 3 or index == middle_index:
		return 0.0
	return -side_card_rotation_degrees if index < middle_index else side_card_rotation_degrees


func _find_hovered_reward_card() -> CardVisual:
	var mouse_position: Vector2 = get_global_mouse_position()
	for index in range(_reward_cards.size() - 1, -1, -1):
		var card: CardVisual = _reward_cards[index]
		if is_instance_valid(card) and card._contains_visual_point(mouse_position):
			return card
	return null


func _create_dim_overlay() -> void:
	_dim_overlay = ColorRect.new()
	_dim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(_dim_overlay)
	_dim_overlay.hide()


func _connect_booster_packs() -> void:
	_booster_packs.clear()
	for node in get_tree().get_nodes_in_group("booster_packs"):
		var pack: BoosterPack = node as BoosterPack
		if not pack:
			continue
		_booster_packs.append(pack)
		if not pack.open_requested.is_connected(_on_pack_open_requested):
			pack.open_requested.connect(_on_pack_open_requested)


func _close_other_products(active_pack: BoosterPack) -> void:
	for product in get_tree().get_nodes_in_group("shop_purchasables"):
		if product != active_pack:
			product.play_shop_close()


func _reopen_products() -> void:
	for product in get_tree().get_nodes_in_group("shop_purchasables"):
		product.restore_after_reward()


func _get_wallet() -> ShopWallet:
	return get_tree().get_first_node_in_group("shop_wallets") as ShopWallet


func _get_random_generator() -> RandomNumberGenerator:
	var shop_random: ShopRandom = get_tree().get_first_node_in_group("shop_random") as ShopRandom
	return shop_random.generator if shop_random else null


func _set_collection_locked(locked: bool) -> void:
	var collection: CardCollection = get_tree().get_first_node_in_group("card_collections") as CardCollection
	if collection:
		await collection.set_choice_locked(locked)


func _set_active(active: bool) -> void:
	if _active == active:
		return
	_active = active
	activity_changed.emit(_active)
