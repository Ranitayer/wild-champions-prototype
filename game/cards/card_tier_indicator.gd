@tool
class_name CardTierIndicator
extends Control

const MAX_TIER := 3
const OUTLINE_WIDTH := 4.0
const DARK_COLOR := Color("151d28")
const UNLOCKED_COLOR := Color("de9e41")
const RADIUS := 6.0

@export_group("Layout")
@export_range(0.0, 80.0, 1.0) var top_margin := 12.0:
	set(value):
		top_margin = maxf(0.0, value)
		_update_layout()
@export_range(0.0, 40.0, 1.0) var right_margin := 5.0:
	set(value):
		right_margin = maxf(0.0, value)
		_update_layout()
@export_range(0.0, 20.0, 1.0) var circle_gap := 5.0:
	set(value):
		circle_gap = maxf(0.0, value)
		_update_layout()

var max_tier := MAX_TIER:
	set(value):
		max_tier = clampi(value, 1, MAX_TIER)
		_update_layout()
var tier := 1:
	set(value):
		tier = clampi(value, 1, max_tier)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_layout()


func _update_layout() -> void:
	var diameter := RADIUS * 2.0
	size = Vector2(diameter, diameter * max_tier + circle_gap * (max_tier - 1))
	var parent_control := get_parent() as Control
	if parent_control:
		position = Vector2(parent_control.size.x - right_margin - size.x, top_margin)
	queue_redraw()


func _draw() -> void:
	for row in range(max_tier):
		var tier_number := max_tier - row
		var center := Vector2(RADIUS, RADIUS + row * (RADIUS * 2.0 + circle_gap))
		draw_circle(center, RADIUS, DARK_COLOR, true, -1.0, true)
		if tier_number <= tier:
			draw_circle(center, RADIUS - OUTLINE_WIDTH, UNLOCKED_COLOR, true, -1.0, true)
