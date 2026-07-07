class_name ShopSellManager
extends Node

const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const SELL_COLOR := Color("de9e41")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")
const ZONE_MARGIN := 25.0
var _sell_zone: Panel
var _selling: bool = false
var _shop_active: bool = false

@onready var arena: BattleArena = get_parent() as BattleArena
@onready var shop_transition: ShopTransition = $"../ShopTransition" as ShopTransition


func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	_build_sell_zone()
	shop_transition.shop_state_changed.connect(_on_shop_state_changed)
	get_tree().node_added.connect(_on_node_added)
	get_viewport().size_changed.connect(_position_sell_zone)
	for node in get_tree().get_nodes_in_group("card_visuals"):
		_connect_card(node as CardVisual)


func _on_shop_state_changed(active: bool) -> void:
	_shop_active = active
	_position_sell_zone()
	if _sell_zone:
		_sell_zone.hide()
	_refresh_sell_prices()


func _on_node_added(node: Node) -> void:
	var card: CardVisual = node as CardVisual
	if card:
		_connect_card(card)
		if card.is_node_ready():
			_update_card_sell_price(card)
		else:
			card.ready.connect(_update_card_sell_price.bind(card), CONNECT_ONE_SHOT)


func _connect_card(card: CardVisual) -> void:
	if not card:
		return
	if not card.drag_started.is_connected(_on_card_drag_started):
		card.drag_started.connect(_on_card_drag_started)
	if not card.sell_requested.is_connected(_on_card_sell_requested):
		card.sell_requested.connect(_on_card_sell_requested)
	if not card.tier_changed.is_connected(_on_card_tier_changed):
		card.tier_changed.connect(_on_card_tier_changed)
	if not card.slotted.is_connected(_on_card_drag_finished):
		card.slotted.connect(_on_card_drag_finished)
	if not card.invalid_drop_requested.is_connected(_on_card_drag_finished):
		card.invalid_drop_requested.connect(_on_card_drag_finished)
	if not card.merge_started.is_connected(_on_card_merge_started):
		card.merge_started.connect(_on_card_merge_started)


func _on_card_drag_started(card: CardVisual) -> void:
	if _shop_active and _is_sellable(card):
		_position_sell_zone()
		if _sell_zone:
			_sell_zone.show()


func _on_card_sell_requested(card: CardVisual) -> void:
	if not _shop_active or _selling or not _is_sellable(card):
		return
	_selling = true
	var price: int = CardSellPrice.get_price(card.card_data, card.get_card_tier())
	card.set_interaction_blocked(true)
	card.hide_sell_price()
	var collection: CardCollection = get_tree().get_first_node_in_group("card_collections") as CardCollection
	if collection:
		collection.forget_dragged_card(card)
	var wallet: ShopWallet = get_tree().get_first_node_in_group("shop_wallets") as ShopWallet
	if wallet:
		wallet.add_coins(price)
	if _sell_zone:
		await card.play_sell_drop(_get_sell_snap_position(card))
	if not is_instance_valid(card):
		if _sell_zone:
			_sell_zone.hide()
		_selling = false
		return
	await card.play_dissolve_animation()
	if is_instance_valid(card):
		card.queue_free()
	if _sell_zone:
		_sell_zone.hide()
	_refresh_sell_prices()
	_selling = false


func _on_card_drag_finished(_card: CardVisual) -> void:
	if _sell_zone:
		_sell_zone.hide()


func _on_card_merge_started(_source: CardVisual, _target: CardVisual) -> void:
	if _sell_zone:
		_sell_zone.hide()


func _on_card_tier_changed(card: CardVisual, _tier: int) -> void:
	_update_card_sell_price(card)


func _refresh_sell_prices() -> void:
	for node in get_tree().get_nodes_in_group("card_visuals"):
		_update_card_sell_price(node as CardVisual)


func _update_card_sell_price(card: CardVisual) -> void:
	if not is_instance_valid(card):
		return
	if _shop_active and _is_sellable(card):
		card.show_sell_price(CardSellPrice.get_price(card.card_data, card.get_card_tier()), SELL_COLOR)
	else:
		card.hide_sell_price()


func _is_sellable(card: CardVisual) -> bool:
	return (
		is_instance_valid(card)
		and card.card_data != null
		and not card.has_meta("shop_offer_card")
		and not card.has_meta("booster_reward_card")
	)


func _build_sell_zone() -> void:
	_sell_zone = Panel.new()
	_sell_zone.size = CardMetrics.SIZE
	_sell_zone.custom_minimum_size = CardMetrics.SIZE
	_sell_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sell_zone.add_to_group("card_sell_zones")
	_sell_zone.add_theme_stylebox_override("panel", _make_sell_style())
	_sell_zone.hide()
	arena.add_child(_sell_zone)

	var label: Label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = "SELL"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", CARD_FONT)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", LIGHT_COLOR)
	_sell_zone.add_child(label)


func _make_sell_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_color = LIGHT_COLOR
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	return style


func _position_sell_zone() -> void:
	if not _sell_zone or not arena:
		return
	_sell_zone.position = arena.bottom_slots.position + Vector2(arena.bottom_slots.size.x + ZONE_MARGIN, 0.0)


func _get_sell_snap_position(card: CardVisual) -> Vector2:
	return _sell_zone.global_position + (_sell_zone.size - card.size) * 0.5
