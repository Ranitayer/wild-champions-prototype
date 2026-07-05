class_name StatPopup
extends Node

const LIGHT_COLOR := Color("ebede9")
const FONT_OUTLINE_SIZE := 16
const CARD_FONT := preload("res://assets/fonts/cardfont.ttf")

@export_group("Timing")
@export_range(0.1, 5.0, 0.1) var display_duration := 0.85

@export_group("Layout")
@export_range(8, 64, 1) var font_size := 24
@export_range(-45.0, 45.0, 1.0) var rotation_degrees := -15.0

var fade_duration := 0.15
var stat_margin := 6.0
var stack_spacing := 4.0
var rise_distance := 8.0

var _popup_count_by_key: Dictionary = {}


func show_change(card: CardVisual, stat_type: CardStat.Type, delta: int) -> void:
	if delta == 0 or not is_instance_valid(card):
		return
	var label := _create_label("%+d" % delta, CardStat.color(stat_type))
	var key := "%d:%d" % [card.get_instance_id(), stat_type]
	var stack_index := int(_popup_count_by_key.get(key, 0))
	var anchor := card.get_stat_popup_anchor(stat_type)
	var stack_offset := stack_index * (label.size.y + stack_spacing)
	if stat_type == CardStat.Type.COOLDOWN:
		label.global_position = anchor - Vector2(label.size.x + stat_margin + stack_offset, label.size.y * 0.5)
	else:
		label.global_position = anchor + Vector2(-label.size.x * 0.5, stat_margin + stack_offset)
	await _play_popup(label, key)


func _create_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", CARD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", LIGHT_COLOR)
	label.add_theme_constant_override("outline_size", FONT_OUTLINE_SIZE)
	get_parent().add_child(label)
	label.size = label.get_combined_minimum_size()
	label.pivot_offset = label.size * 0.5
	label.rotation_degrees = rotation_degrees
	return label


func _play_popup(label: Label, key: String) -> void:
	_popup_count_by_key[key] = int(_popup_count_by_key.get(key, 0)) + 1
	var end_position := label.global_position + Vector2.UP * rise_distance

	var tween := label.create_tween()
	tween.tween_interval(display_duration)
	tween.tween_property(label, "global_position", end_position, fade_duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, fade_duration)
	await tween.finished
	_popup_count_by_key[key] = maxi(0, int(_popup_count_by_key.get(key, 1)) - 1)
	label.queue_free()
