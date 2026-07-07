class_name InitiativeRollPopup
extends Node

const LIGHT_COLOR := Color("#ebede9")
const DARK_COLOR := Color("#151d28")
const ATTACK_COLOR := Color("#4f8fba")
const HEALTH_COLOR := Color("#a53030")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")

@export var box_size := Vector2(520.0, 100.0)
@export var corner_radius := 8
@export var roll_seconds := 2.0
@export var start_interval := 0.06
@export var interval_growth := 1.16
@export var final_hold_seconds := 1.0
@export var zoom_duration := 0.18

var _root: Control
var _panel: Panel
var _final_row: HBoxContainer
var _final_name: Label
var _final_text: Label


func _ready() -> void:
	_build_ui()


func show_roll(first_name: String, second_name: String, favored_name: String, favored_is_local := true) -> void:
	_root.show()
	_panel.show()
	_panel.scale = Vector2.ZERO
	_set_roll_name(first_name, true)

	var zoom_in: Tween = create_tween()
	zoom_in.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	zoom_in.tween_property(_panel, "scale", Vector2.ONE, zoom_duration)
	await zoom_in.finished

	var names: Array[String] = [first_name, second_name]
	var elapsed: float = 0.0
	var interval: float = start_interval
	var index: int = 0
	while elapsed < roll_seconds:
		var name_index: int = index % names.size()
		_set_roll_name(names[name_index], name_index == 0)
		await get_tree().create_timer(interval).timeout
		elapsed += interval
		interval *= interval_growth
		index += 1

	_set_favored_text(favored_name, favored_is_local)
	await get_tree().create_timer(final_hold_seconds).timeout

	var zoom_out: Tween = create_tween()
	zoom_out.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	zoom_out.tween_property(_panel, "scale", Vector2.ZERO, zoom_duration)
	await zoom_out.finished
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
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(_panel)

	var final_center: CenterContainer = CenterContainer.new()
	final_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(final_center)

	_final_row = HBoxContainer.new()
	_final_row.alignment = BoxContainer.ALIGNMENT_CENTER
	final_center.add_child(_final_row)

	_final_name = _make_final_label()
	_final_row.add_child(_final_name)

	_final_text = _make_final_label()
	_final_text.text = " is favored this battle"
	_final_text.add_theme_color_override("font_color", DARK_COLOR)
	_final_row.add_child(_final_text)
	_final_row.hide()

	_root.hide()
	_panel.hide()


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = LIGHT_COLOR
	style.set_corner_radius_all(corner_radius)
	return style


func _make_final_label() -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", CARD_FONT)
	label.add_theme_font_size_override("font_size", 28)
	return label


func _set_favored_text(player_name: String, is_local: bool) -> void:
	_set_roll_name(player_name, is_local)
	_final_text.show()


func _set_roll_name(player_name: String, is_local: bool) -> void:
	var favored_color: Color = ATTACK_COLOR if is_local else HEALTH_COLOR
	_final_name.text = player_name
	_final_name.add_theme_color_override("font_color", favored_color)
	_final_text.hide()
	_final_row.show()
