class_name EffectPopup
extends Node

const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const FONT_OUTLINE_SIZE := 16
const CARD_FONT := preload("res://assets/fonts/cardfont.ttf")

@export_group("Timing")
@export_range(0.1, 5.0, 0.1) var display_duration := 0.65

@export_group("Text")
@export_range(8, 128, 1) var font_size := 70
@export_range(-45.0, 45.0, 1.0) var rotation_degrees := -15.0

var fade_duration := 0.15
var text_color := DARK_COLOR
var start_scale := 0.3
var pop_scale := 1.2
var pop_duration := 0.10
var settle_duration := 0.10


func show_text(card: CardVisual, text: String, color := Color.TRANSPARENT) -> void:
	if not is_instance_valid(card):
		return
	var resolved_color := text_color if color == Color.TRANSPARENT else color
	var label := _create_label(text, card, resolved_color)
	await _play(label)


func _create_label(text: String, card: CardVisual, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", CARD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", LIGHT_COLOR)
	label.add_theme_constant_override("outline_size", FONT_OUTLINE_SIZE)
	get_parent().add_child(label)
	label.size = card.card_size
	label.global_position = card.get_card_center() - label.size * 0.5
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * start_scale
	label.rotation_degrees = rotation_degrees
	return label


func _play(label: Label) -> void:
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * pop_scale, pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, settle_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(display_duration)
	tween.tween_property(label, "modulate:a", 0.0, fade_duration)
	await tween.finished
	label.queue_free()
