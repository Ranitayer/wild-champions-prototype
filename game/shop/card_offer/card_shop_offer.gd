class_name CardShopOffer
extends Control

const CARD_SCENE := preload("res://game/cards/card_template.tscn")
const STAT_SCENE := preload("res://game/cards/stat_circle.tscn")
const DEFAULT_OFFER_POOL: Resource = preload("res://content/shop/card_offer_pool.tres")
const PRICE_COLOR := Color("de9e41")
const PRICE_STAT_SIZE := 55.0

@export var offer_pool: Resource = DEFAULT_OFFER_POOL
@export var center_offset_x := 260.0
@export_range(0.1, 2.0, 0.05) var slide_duration := 0.55
@export_range(0.05, 0.5, 0.01) var close_zoom_duration := 0.22
@export_range(0.0, 0.5, 0.01) var close_end_scale := 0.05

var _card: CardVisual
var _price_stat: StatCircle
var _motion_tween: Tween
var _purchasing := false

@onready var floating_effect: FloatingEffect = $FloatingEffect


func _enter_tree() -> void:
	add_to_group("shop_purchasables")


func _ready() -> void:
	hide()
	custom_minimum_size = CardMetrics.SIZE
	size = CardMetrics.SIZE
	_create_price_stat()
	_roll_offer()
	get_viewport().size_changed.connect(_position_offer)


func play_shop_open() -> void:
	if not is_instance_valid(_card):
		_roll_offer()
	_position_offer()
	scale = Vector2.ONE
	modulate.a = 1.0
	var target_position: Vector2 = global_position
	global_position = Vector2(
		target_position.x,
		get_viewport().get_visible_rect().position.y - size.y
	)
	show()
	_kill_tween()
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "global_position", target_position, slide_duration)
	await _motion_tween.finished
	_start_card_float()


func restore_after_reward() -> void:
	if is_instance_valid(_card):
		play_shop_open()


func play_shop_close() -> void:
	if not visible:
		return
	floating_effect.stop()
	_kill_tween()
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * close_end_scale, close_zoom_duration)
	_motion_tween.tween_property(self, "modulate:a", 0.0, close_zoom_duration)
	await _motion_tween.finished
	hide()


func is_busy() -> bool:
	return _purchasing


func _roll_offer() -> void:
	var pool: CardShopOfferData = offer_pool as CardShopOfferData
	if not pool:
		return
	var cards: Array[CardData] = pool.pick_rewards(1, _get_random_generator())
	if cards.is_empty():
		return
	if is_instance_valid(_card):
		_card.queue_free()
	_card = CARD_SCENE.instantiate() as CardVisual
	_card.card_data = cards[0]
	add_child(_card)
	move_child(_card, 0)
	_card.set_card_tier(1)
	_configure_offer_card(_card)
	_price_stat.value = pool.get_price(_card.card_data.rarity)
	if visible:
		_start_card_float()


func _create_price_stat() -> void:
	_price_stat = STAT_SCENE.instantiate() as StatCircle
	add_child(_price_stat)
	_price_stat.size = Vector2.ONE * PRICE_STAT_SIZE
	_price_stat.fill_color = PRICE_COLOR
	_price_stat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_price_stat.z_index = 100
	_price_stat.hide()


func _request_purchase(card: CardVisual) -> bool:
	if not _purchasing:
		_purchase(card)
	return false


func _purchase(card: CardVisual) -> void:
	_purchasing = true
	floating_effect.stop()
	card.set_interaction_blocked(true, true)
	var wallet: ShopWallet = _get_wallet()
	if not wallet:
		card.set_interaction_blocked(false)
		_start_card_float()
		_purchasing = false
		return
	var purchase_succeeded: bool = await wallet.try_spend(
		_price_stat.value,
		_price_stat,
		card.card_surface
	)
	if not purchase_succeeded:
		card.set_interaction_blocked(false)
		_start_card_float()
		_purchasing = false
		return
	card.set_interaction_blocked(false)
	card.clear_drag_guard()
	card.remove_hover_control(_price_stat)
	_price_stat.reparent(self, false)
	_price_stat.hide()
	card.reparent(get_tree().current_scene, true)
	_card = null
	var collection: CardCollection = _get_card_collection()
	if collection:
		await collection.collect_card(card)
	else:
		card.queue_free()
	_purchasing = false


func _configure_offer_card(card: CardVisual) -> void:
	if not card.hover_changed.is_connected(_on_card_hover_changed):
		card.hover_changed.connect(_on_card_hover_changed)
	card.set_drag_guard(_request_purchase.bind(card))
	card.tier_indicator.top_margin = 52.0
	_price_stat.reparent(card.card_surface, false)
	_position_price_stat()
	card.add_hover_control(_price_stat)
	_price_stat.show()

func _get_card_collection() -> CardCollection:
	return get_tree().get_first_node_in_group("card_collections") as CardCollection


func _get_wallet() -> ShopWallet:
	return get_tree().get_first_node_in_group("shop_wallets") as ShopWallet


func _get_random_generator() -> RandomNumberGenerator:
	var shop_random: ShopRandom = get_tree().get_first_node_in_group("shop_random") as ShopRandom
	return shop_random.generator if shop_random else null


func _position_price_stat() -> void:
	_price_stat.position = Vector2(CardMetrics.SIZE.x - PRICE_STAT_SIZE + 12.0, -12.0)


func _on_card_hover_changed(card: CardVisual, hovered: bool) -> void:
	if card != _card:
		return
	if hovered:
		floating_effect.stop()
	elif visible:
		_start_card_float()


func _start_card_float() -> void:
	if is_instance_valid(_card):
		floating_effect.start(_card)


func _position_offer() -> void:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	global_position = Vector2(
		viewport_rect.position.x + viewport_rect.size.x * 0.5 - size.x * 0.5 + center_offset_x,
		viewport_rect.position.y + viewport_rect.size.y * 0.5 - size.y
	)


func _kill_tween() -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
