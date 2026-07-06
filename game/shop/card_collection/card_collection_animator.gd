class_name CardCollectionAnimator
extends Node

@export var travel_duration := 0.5


func play(card: CardVisual, target: Vector2) -> void:
	card.prepare_for_collection()
	var direction := target - card.get_card_center()
	var target_position := target - card.size * 0.5
	var target_rotation := rad_to_deg(direction.angle()) + 90.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "global_position", target_position, travel_duration)
	tween.tween_property(card.card_surface, "rotation_degrees", target_rotation, travel_duration)
	tween.tween_property(card.card_surface, "scale", Vector2.ZERO, travel_duration)
	await tween.finished
