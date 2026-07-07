class_name MatchResultPopup
extends Node

const LIGHT_COLOR := Color("#ebede9")
const DARK_COLOR := Color("#151d28")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")

@export var box_size := Vector2(460.0, 110.0)
@export var corner_radius := 8
@export var zoom_in_duration := 0.18
@export var hold_seconds := 1.0
@export var slide_duration := 0.25
@export var final_hold_seconds := 0.5
@export var zoom_out_duration := 0.18

var _root: Control
var _panel: Panel
var _black_fill: Panel
var _label: Label


func _ready() -> void:
	_build_ui()


func show_winner(player_name: String) -> void:
	_label.text = "%s won!" % player_name
	_label.add_theme_color_override("font_color", DARK_COLOR)
	_panel.scale = Vector2.ZERO
	_panel.show()
	_root.show()
	_black_fill.size.x = 0.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "scale", Vector2.ONE, zoom_in_duration)
	tween.tween_interval(hold_seconds)
	tween.tween_property(_black_fill, "size:x", box_size.x, slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_set_text_white)
	tween.tween_interval(final_hold_seconds)
	tween.tween_property(_panel, "scale", Vector2.ZERO, zoom_out_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	_root.hide()
	_panel.hide()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	_panel = Panel.new()
	_panel.custom_minimum_size = box_size
	_panel.size = box_size
	_panel.pivot_offset = box_size * 0.5
	_panel.clip_contents = true
	_panel.add_theme_stylebox_override("panel", _make_panel_style(LIGHT_COLOR))
	center.add_child(_panel)

	_black_fill = Panel.new()
	_black_fill.position = Vector2.ZERO
	_black_fill.size = Vector2(0.0, box_size.y)
	_black_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black_fill.add_theme_stylebox_override("panel", _make_panel_style(DARK_COLOR))
	_panel.add_child(_black_fill)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", CARD_FONT)
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_color", DARK_COLOR)
	_panel.add_child(_label)

	_root.hide()
	_panel.hide()


func _make_panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(corner_radius)
	return style


func _set_text_white() -> void:
	_label.add_theme_color_override("font_color", LIGHT_COLOR)
