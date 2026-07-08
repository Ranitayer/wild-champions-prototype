class_name MatchResultPopup
extends Node

const LIGHT_COLOR := Color("#ebede9")
const DARK_COLOR := Color("#151d28")
const PLAYER_COLOR := Color("#4f8fba")
const ENEMY_COLOR := Color("#a53030")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")

@export var box_size: Vector2 = Vector2(460.0, 110.0)
@export var corner_radius: int = 8
@export var zoom_in_duration: float = 0.28
@export_range(0.1, 1.0, 0.01) var spawn_start_scale: float = 0.55
@export var hold_seconds: float = 1.0
@export var slide_duration: float = 0.25
@export var final_hold_seconds: float = 0.5
@export var zoom_out_duration: float = 0.18
@export var marker_size: float = 28.0
@export var marker_pop_scale: float = 1.22
@export var marker_hold_seconds: float = 1.0
@export var marker_fly_duration: float = 0.35

var _root: Control
var _panel: Panel
var _black_fill: Panel
var _label: Label
var _popup_tween: Tween


func _ready() -> void:
	_build_ui()


func show_winner(
	player_name: String,
	is_local: bool = true,
	target_position: Vector2 = Vector2.ZERO,
	has_target: bool = false,
	arrived_callback: Callable = Callable()
) -> void:
	_label.text = "%s won!" % player_name
	_label.add_theme_color_override("font_color", DARK_COLOR)
	_panel.size = box_size
	_panel.pivot_offset = box_size * 0.5
	_panel.scale = Vector2.ONE * spawn_start_scale
	_panel.modulate.a = 0.0
	_panel.show()
	_root.show()
	_black_fill.size.x = 0.0

	if _popup_tween and _popup_tween.is_valid():
		_popup_tween.kill()
	var tween: Tween = create_tween()
	_popup_tween = tween
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "scale", Vector2.ONE, zoom_in_duration)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, zoom_in_duration)
	tween.tween_interval(hold_seconds)
	tween.tween_property(_black_fill, "size:x", box_size.x, slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_set_text_white)
	tween.tween_interval(final_hold_seconds)
	await tween.finished
	await _play_score_marker(is_local, target_position, has_target, arrived_callback)


func _play_score_marker(is_local: bool, target_position: Vector2, has_target: bool, arrived_callback: Callable) -> void:
	var start_position: Vector2 = _panel.global_position + _panel.size * 0.5
	var shrink_tween: Tween = create_tween()
	shrink_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	shrink_tween.tween_property(_panel, "scale", Vector2.ZERO, zoom_out_duration)
	await shrink_tween.finished
	_panel.hide()

	var marker: Panel = Panel.new()
	marker.size = Vector2.ONE * marker_size
	marker.pivot_offset = marker.size * 0.5
	marker.global_position = start_position - marker.pivot_offset
	marker.scale = Vector2.ZERO
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_theme_stylebox_override("panel", _make_panel_style(PLAYER_COLOR if is_local else ENEMY_COLOR, 999))
	_root.add_child(marker)

	var marker_tween: Tween = create_tween()
	marker_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	marker_tween.tween_property(marker, "scale", Vector2.ONE * marker_pop_scale, zoom_out_duration)
	marker_tween.tween_property(marker, "scale", Vector2.ONE, zoom_out_duration)
	marker_tween.tween_interval(marker_hold_seconds)
	if has_target:
		marker_tween.tween_property(marker, "global_position", target_position - marker.pivot_offset, marker_fly_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await marker_tween.finished
	if has_target:
		marker.hide()
		marker.queue_free()
		if arrived_callback.is_valid():
			arrived_callback.call()
		_root.hide()
		return
	if arrived_callback.is_valid():
		arrived_callback.call()
	var pop_tween: Tween = create_tween()
	pop_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(marker, "scale", Vector2.ONE * marker_pop_scale, zoom_out_duration)
	pop_tween.tween_property(marker, "scale", Vector2.ZERO, zoom_out_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await pop_tween.finished
	marker.queue_free()
	_root.hide()


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
	_panel.add_theme_stylebox_override("panel", _make_panel_style(LIGHT_COLOR, corner_radius))
	center.add_child(_panel)

	_black_fill = Panel.new()
	_black_fill.position = Vector2.ZERO
	_black_fill.size = Vector2(0.0, box_size.y)
	_black_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black_fill.add_theme_stylebox_override("panel", _make_panel_style(DARK_COLOR, corner_radius))
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


func _make_panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


func _set_text_white() -> void:
	_label.add_theme_color_override("font_color", LIGHT_COLOR)
