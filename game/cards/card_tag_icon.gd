@tool
class_name CardTagIcon
extends Control

const LIGHT_COLOR := Color("ebede9")

var outline_width := 2.0:
	set(value):
		outline_width = value
		queue_redraw()

var icon_margin := 7.0:
	set(value):
		icon_margin = value
		_layout_icon()

var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if _icon != null:
			_icon.texture = value

var _icon: TextureRect


func _ready() -> void:
	_icon = TextureRect.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_icon)
	_icon.texture = icon_texture
	_layout_icon()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - outline_width * 0.5
	draw_arc(center, radius, 0.0, TAU, 64, LIGHT_COLOR, outline_width, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
		_layout_icon()


func _layout_icon() -> void:
	if _icon == null:
		return
	var margin: float = minf(icon_margin, minf(size.x, size.y) * 0.35)
	_icon.position = Vector2.ONE * margin
	_icon.size = Vector2(maxf(0.0, size.x - margin * 2.0), maxf(0.0, size.y - margin * 2.0))
