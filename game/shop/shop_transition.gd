class_name ShopTransition
extends Node

signal shop_state_changed(active: bool)

@export_group("Motion")
@export var anticipation_distance := 24.0
@export var travel_duration := 0.45
@export var bottom_margin := 30.0
@export var booster_rewards_path: NodePath = ^"../ShopLayer/BoosterPackRewards"
@export var card_offer_path: NodePath = ^"../ShopLayer/CardShopOffer"
@export var wallet_path: NodePath = ^"../ShopLayer/WalletAnchor/ShopWallet"

@export_group("Colors")
@export var battle_slot_color := Color("468232")
@export var shop_slot_color := Color("19332d")
@export var battle_background_color := Color("75a743")
@export var shop_background_color := Color("25562e")

@onready var arena: BattleArena = get_parent() as BattleArena
@onready var background: ColorRect = %Background
@onready var booster_rewards: BoosterPackRewards = get_node_or_null(booster_rewards_path) as BoosterPackRewards
@onready var card_offer: CardShopOffer = get_node_or_null(card_offer_path) as CardShopOffer
@onready var wallet: ShopWallet = get_node_or_null(wallet_path) as ShopWallet

var _transitioning := false
var _in_shop := false
var _positions_captured := false
var _battle_top_position := Vector2.ZERO
var _battle_bottom_position := Vector2.ZERO
var _motion_tween: Tween
var _color_tween: Tween


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not key_event or key_event.keycode != KEY_F2 or not key_event.pressed or key_event.echo:
		return
	if (
		_transitioning
		or arena.combat.is_running()
		or (wallet and wallet.is_busy())
		or (card_offer and card_offer.is_busy())
		or (booster_rewards and booster_rewards.is_active())
	):
		return
	set_shop_active(not _in_shop)
	get_viewport().set_input_as_handled()


func is_shop_active() -> bool:
	return _in_shop


func set_shop_active(active: bool) -> void:
	if _transitioning or active == _in_shop:
		return
	await _transition_to(active)


func _transition_to(shop_active: bool) -> void:
	_capture_battle_positions()
	_transitioning = true
	_kill_motion_tween()
	if not shop_active:
		await _set_shop_products_visible(false)
	if shop_active:
		arena.set_shop_active(true)
	var viewport_rect := get_viewport().get_visible_rect()
	var top_target := _battle_top_position
	var bottom_target := _battle_bottom_position
	if shop_active:
		top_target.y = viewport_rect.position.y - arena.global_position.y - arena.top_slots.size.y - anticipation_distance
		bottom_target.y = viewport_rect.end.y - arena.global_position.y - bottom_margin - arena.bottom_slots.size.y
	var top_delta := top_target - arena.top_slots.position
	var bottom_delta := bottom_target - arena.bottom_slots.position
	var top_cards := _get_row_cards(arena.top_slots)
	var bottom_cards := _get_row_cards(arena.bottom_slots)
	_animate_colors(shop_active)

	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween_row_and_cards(
		_motion_tween,
		arena.top_slots,
		top_cards,
		top_delta,
		travel_duration
	)
	_tween_row_and_cards(
		_motion_tween,
		arena.bottom_slots,
		bottom_cards,
		bottom_delta,
		travel_duration
	)
	await _motion_tween.finished
	if shop_active:
		await _set_shop_products_visible(true)
	_in_shop = shop_active
	if not shop_active:
		arena.set_shop_active(false)
	_transitioning = false
	shop_state_changed.emit(_in_shop)


func _capture_battle_positions() -> void:
	if _positions_captured:
		return
	_battle_top_position = arena.top_slots.position
	_battle_bottom_position = arena.bottom_slots.position
	_positions_captured = true


func _kill_motion_tween() -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()


func _animate_colors(shop_active: bool) -> void:
	var target_background := shop_background_color if shop_active else battle_background_color
	var target_slot := shop_slot_color if shop_active else battle_slot_color
	_color_tween = create_tween().set_parallel(true)
	_color_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_color_tween.tween_property(
		background,
		"color",
		target_background,
		travel_duration
	)
	for slot in arena.get_all_slots():
		_color_tween.tween_method(
			slot.set_background_color,
			slot.get_background_color(),
			target_slot,
			travel_duration
		)


func _get_row_cards(row: HBoxContainer) -> Array[CardVisual]:
	var cards: Array[CardVisual] = []
	for child in row.get_children():
		var slot := child as CardSlot
		if slot and slot.has_card():
			cards.append(slot.get_card())
	return cards


func _tween_row_and_cards(
	tween: Tween,
	row: HBoxContainer,
	cards: Array[CardVisual],
	delta: Vector2,
	duration: float
) -> void:
	tween.tween_property(row, "position", row.position + delta, duration)
	for card in cards:
		if is_instance_valid(card):
			tween.tween_property(card, "global_position", card.global_position + delta, duration)


func _set_shop_products_visible(show_products: bool) -> void:
	var wait_duration := 0.0
	for node in get_tree().get_nodes_in_group("booster_packs"):
		var pack: BoosterPack = node as BoosterPack
		if not pack:
			continue
		if show_products:
			pack.play_shop_open()
			wait_duration = maxf(wait_duration, pack.slide_duration)
		else:
			pack.play_shop_close()
			wait_duration = maxf(
				wait_duration,
				pack.close_anticipation_duration + pack.close_zoom_duration
			)
	if card_offer:
		if show_products:
			card_offer.play_shop_open()
			wait_duration = maxf(wait_duration, card_offer.slide_duration)
		else:
			card_offer.play_shop_close()
	if wallet:
		if show_products:
			wallet.play_shop_open()
		else:
			wallet.play_shop_close()
	if wait_duration > 0.0:
		await get_tree().create_timer(wait_duration).timeout
