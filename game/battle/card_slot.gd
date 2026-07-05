class_name CardSlot
extends Panel

const TEAM_ENEMY := 0
const TEAM_PLAYER := 1

var team := TEAM_PLAYER
var slot_index := 0
var occupying_card: CardVisual


func _ready() -> void:
	add_to_group("card_slots")


func can_accept(card: Control) -> bool:
	var card_center := card.global_position + card.size * 0.5
	return (not occupying_card or occupying_card == card) and get_global_rect().has_point(card_center)


func occupy(card: CardVisual) -> void:
	occupying_card = card
	self_modulate = Color(1.0, 1.0, 1.0, 0.0)


func release(card: CardVisual) -> void:
	if occupying_card == card:
		occupying_card = null
		self_modulate = Color.WHITE


func has_card() -> bool:
	return occupying_card != null and is_instance_valid(occupying_card)


func get_card() -> CardVisual:
	if has_card():
		return occupying_card
	return null


func get_snap_position(card_size: Vector2) -> Vector2:
	return global_position + (size - card_size) * 0.5
