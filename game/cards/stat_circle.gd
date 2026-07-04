@tool
class_name StatCircle
extends Control

const OUTLINE_WIDTH := 4.0
const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")

@export var fill_color: Color = Color("4f8fba"):
	set(value):
		fill_color = value
		queue_redraw()
@export_range(0, 999, 1) var value: int = 0:
	set(new_value):
		value = new_value
		_update_label()
@export_range(8, 48, 1) var value_font_size: int = 22:
	set(new_size):
		value_font_size = new_size
		_update_label()

@onready var value_label: Label = %ValueLabel


func _ready() -> void:
	_update_label()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	draw_circle(center, radius, DARK_COLOR, true, -1.0, true)
	draw_circle(center, radius - OUTLINE_WIDTH, LIGHT_COLOR, true, -1.0, true)
	draw_circle(center, radius - OUTLINE_WIDTH * 2.0, fill_color, true, -1.0, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _update_label() -> void:
	if not is_node_ready():
		return
	value_label.text = str(value)
	value_label.add_theme_font_size_override("font_size", value_font_size)
