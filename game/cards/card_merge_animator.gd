class_name CardMergeAnimator
extends Node

@export_group("Slam")
@export_range(0.05, 0.5, 0.01) var align_duration := 0.14
@export_range(0.03, 0.4, 0.01) var anticipation_duration := 0.10
@export_range(0.0, 80.0, 1.0) var slam_height := 28.0
@export_range(0.03, 0.3, 0.01) var slam_duration := 0.08
@export_range(0.02, 0.35, 0.01) var squash_amount := 0.14

@export_group("Bounce")
@export_range(0.0, 40.0, 1.0) var bounce_height := 12.0
@export_range(0.05, 0.6, 0.01) var bounce_duration := 0.22


func play(source: CardVisual, target: CardVisual) -> void:
	if not is_instance_valid(source) or not is_instance_valid(target):
		return
	var target_z := target.z_index
	source.prepare_for_merge()
	target.prepare_for_merge()
	source.z_index = CardVisual.DRAG_Z_INDEX
	target.z_index = CardVisual.DRAG_Z_INDEX - 1

	var target_position := target.global_position
	var align_tween := create_tween().set_parallel(true)
	align_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	align_tween.tween_property(
		source,
		"global_position",
		target_position + Vector2.UP * (slam_height * 0.25),
		align_duration
	)
	align_tween.tween_property(source.card_surface, "position", Vector2.ZERO, align_duration)
	align_tween.tween_property(source.card_surface, "scale", Vector2.ONE, align_duration)
	align_tween.tween_property(source.card_surface, "rotation_degrees", 0.0, align_duration)
	align_tween.tween_property(target.card_surface, "position", Vector2.ZERO, align_duration)
	align_tween.tween_property(target.card_surface, "scale", Vector2.ONE, align_duration)
	align_tween.tween_property(target.card_surface, "rotation_degrees", 0.0, align_duration)
	await align_tween.finished

	var anticipation_scale := Vector2(1.0 - squash_amount * 0.35, 1.0 + squash_amount * 0.35)
	var anticipation_tween := create_tween().set_parallel(true)
	anticipation_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anticipation_tween.tween_property(
		source,
		"global_position",
		target_position + Vector2.UP * slam_height,
		anticipation_duration
	)
	anticipation_tween.tween_property(
		source.card_surface,
		"scale",
		anticipation_scale,
		anticipation_duration
	)
	await anticipation_tween.finished

	var squash_scale := Vector2(1.0 + squash_amount, 1.0 - squash_amount)
	var slam_tween := create_tween().set_parallel(true)
	slam_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	slam_tween.tween_property(source, "global_position", target_position, slam_duration)
	slam_tween.tween_property(source.card_surface, "scale", squash_scale, slam_duration)
	slam_tween.tween_property(target.card_surface, "scale", squash_scale, slam_duration)
	await slam_tween.finished

	target.set_card_tier(target.get_card_tier() + 1)
	source.hide()
	source.queue_free()

	var bounce_tween := create_tween().set_parallel(true)
	bounce_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(
		target.card_surface,
		"position:y",
		-bounce_height,
		bounce_duration * 0.5
	)
	bounce_tween.tween_property(
		target.card_surface,
		"scale",
		Vector2(1.0 - squash_amount * 0.25, 1.0 + squash_amount * 0.25),
		bounce_duration * 0.5
	)
	bounce_tween.chain().tween_property(target.card_surface, "position:y", 0.0, bounce_duration * 0.5)
	bounce_tween.parallel().tween_property(target.card_surface, "scale", Vector2.ONE, bounce_duration * 0.5)
	await bounce_tween.finished
	target.finish_merge(target_z)
