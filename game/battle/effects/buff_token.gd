class_name BuffToken
extends Control

const OUTLINE_WIDTH := 4.0
const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const VALUE_FONT_SIZE := 22
const CARD_FONT := preload("res://assets/fonts/cardfont.ttf")

var fill_color := Color("4f8fba"):
	set(value):
		fill_color = value
		queue_redraw()
var value := 0:
	set(new_value):
		value = new_value
		if _value_label:
			_value_label.text = str(value)

var _value_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value_label = Label.new()
	add_child(_value_label)
	_value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value_label.add_theme_font_override("font", CARD_FONT)
	_value_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	_value_label.add_theme_color_override("font_color", LIGHT_COLOR)
	_value_label.text = str(value)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	draw_circle(center, radius, DARK_COLOR, true, -1.0, true)
	draw_circle(center, radius - OUTLINE_WIDTH, LIGHT_COLOR, true, -1.0, true)
	draw_circle(center, radius - OUTLINE_WIDTH * 2.0, fill_color, true, -1.0, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
