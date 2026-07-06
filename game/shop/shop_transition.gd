class_name ShopTransition
extends Node

@export_group("Motion")
@export var anticipation_distance := 24.0
@export var anticipation_duration := 0.12
@export var travel_duration := 0.45
@export var bottom_margin := 15.0

@export_group("Colors")
@export var battle_slot_color := Color("468232")
@export var shop_slot_color := Color("19332d")
@export var battle_background_color := Color("75a743")
@export var shop_background_color := Color("25562e")

@onready var arena: BattleArena = get_parent() as BattleArena
@onready var background: ColorRect = %Background

var _transitioning := false
var _in_shop := false
var _positions_captured := false
var _battle_top_position := Vector2.ZERO
var _battle_bottom_position := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not key_event or key_event.keycode != KEY_F2 or not key_event.pressed or key_event.echo:
		return
	if _transitioning or arena.combat.is_running():
		return
	_transition_to(not _in_shop)
	get_viewport().set_input_as_handled()


func _transition_to(shop_active: bool) -> void:
	_capture_battle_positions()
	_transitioning = true
	if shop_active:
		arena.set_shop_active(true)
	var viewport_rect := get_viewport().get_visible_rect()
	var top_target := _battle_top_position
	var bottom_target := _battle_bottom_position
	if shop_active:
		top_target.y = viewport_rect.position.y - arena.top_slots.size.y - anticipation_distance
		bottom_target.y = viewport_rect.end.y - bottom_margin - arena.bottom_slots.size.y
	var top_delta := top_target - arena.top_slots.global_position
	var bottom_delta := bottom_target - arena.bottom_slots.global_position
	var top_anticipation := _opposite_motion(top_delta) if shop_active else Vector2.ZERO
	var bottom_anticipation := _opposite_motion(bottom_delta) if shop_active else Vector2.ZERO
	var top_cards := _get_row_cards(arena.top_slots)
	var bottom_cards := _get_row_cards(arena.bottom_slots)
	_animate_colors(shop_active)

	if shop_active:
		var anticipation := create_tween().set_parallel(true)
		anticipation.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_row_and_cards(
			anticipation,
			arena.top_slots,
			top_cards,
			top_anticipation,
			anticipation_duration
		)
		_tween_row_and_cards(
			anticipation,
			arena.bottom_slots,
			bottom_cards,
			bottom_anticipation,
			anticipation_duration
		)
		await anticipation.finished

	var travel := create_tween().set_parallel(true)
	if shop_active:
		travel.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	else:
		travel.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween_row_and_cards(
		travel,
		arena.top_slots,
		top_cards,
		top_delta - top_anticipation,
		travel_duration
	)
	_tween_row_and_cards(
		travel,
		arena.bottom_slots,
		bottom_cards,
		bottom_delta - bottom_anticipation,
		travel_duration
	)
	await travel.finished
	_in_shop = shop_active
	if not shop_active:
		arena.set_shop_active(false)
	_transitioning = false


func _capture_battle_positions() -> void:
	if _positions_captured:
		return
	_battle_top_position = arena.top_slots.global_position
	_battle_bottom_position = arena.bottom_slots.global_position
	_positions_captured = true


func _opposite_motion(delta: Vector2) -> Vector2:
	return Vector2(0.0, -signf(delta.y) * anticipation_distance)


func _animate_colors(shop_active: bool) -> void:
	var target_background := shop_background_color if shop_active else battle_background_color
	var target_slot := shop_slot_color if shop_active else battle_slot_color
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		background,
		"color",
		target_background,
		anticipation_duration + travel_duration
	)
	for slot in arena.get_all_slots():
		tween.tween_method(
			slot.set_background_color,
			slot.get_background_color(),
			target_slot,
			anticipation_duration + travel_duration
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
	tween.tween_property(row, "global_position", row.global_position + delta, duration)
	for card in cards:
		if is_instance_valid(card):
			tween.tween_property(card, "global_position", card.global_position + delta, duration)
