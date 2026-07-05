class_name BattleBuffEffect
extends Node

@export_group("Buff Token")
@export_range(0.1, 1.5, 0.01) var travel_duration := 0.42
@export_range(0.0, 360.0, 1.0) var arc_height := 144.0
@export_range(1.0, 5.0, 0.1) var peak_slowdown := 2.5

var source_shrink_scale := 0.88
var source_shrink_duration := 0.10
var source_recover_duration := 0.16
var spawn_offset := Vector2(0.0, -20.0)
var target_offset := Vector2.ZERO
var token_start_scale := 1.0
var token_end_scale := 1.0


func play(source: CardVisual, target: CardVisual, stat_type: CardStat.Type, amount: int) -> void:
	if not is_instance_valid(source) or not is_instance_valid(target):
		return
	await _play(source, target, stat_type, amount, source.get_card_center() + spawn_offset, stat_type)


func play_stat_to_stat(
	card: CardVisual,
	source_stat: CardStat.Type,
	target_stat: CardStat.Type,
	amount: int
) -> void:
	if not is_instance_valid(card):
		return
	await _play(card, card, target_stat, amount, card.get_stat_center(source_stat), source_stat)


func _play(
	source: CardVisual,
	target: CardVisual,
	target_stat: CardStat.Type,
	amount: int,
	start: Vector2,
	visual_stat: CardStat.Type
) -> void:
	await source.play_buff_windup(source_shrink_scale, source_shrink_duration)
	source.start_buff_recovery(source_recover_duration)

	var token := BuffToken.new()
	token.size = source.get_stat_size(visual_stat)
	token.pivot_offset = token.size * 0.5
	token.scale = Vector2.ONE * token_start_scale
	token.fill_color = _get_stat_color(visual_stat)
	token.value = absi(amount)
	get_parent().add_child(token)

	var finish := target.get_stat_center(target_stat) + target_offset
	token.global_position = start - token.size * 0.5
	var tween := token.create_tween().set_parallel(true)
	tween.tween_method(_move_token.bind(token, start, finish), 0.0, 1.0, travel_duration)
	tween.tween_property(token, "scale", Vector2.ONE * token_end_scale, travel_duration)
	await tween.finished
	token.queue_free()
	while is_instance_valid(source) and source.is_buff_animating():
		await source.get_tree().process_frame


func _move_token(raw_progress: float, token: BuffToken, start: Vector2, finish: Vector2) -> void:
	if not is_instance_valid(token):
		return
	var progress := _slow_at_peak(raw_progress)
	var position := start.lerp(finish, progress)
	position.y -= sin(progress * PI) * arc_height
	token.global_position = position - token.size * 0.5


func _slow_at_peak(progress: float) -> float:
	if progress < 0.5:
		return 0.5 * (1.0 - pow(1.0 - progress * 2.0, peak_slowdown))
	return 0.5 + 0.5 * pow(progress * 2.0 - 1.0, peak_slowdown)


func _get_stat_color(stat_type: CardStat.Type) -> Color:
	return CardStat.color(stat_type)
