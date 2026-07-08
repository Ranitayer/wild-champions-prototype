class_name MatchScoreboard
extends Control

signal restart_requested
signal quit_requested

const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const PLAYER_COLOR := Color("4f8fba")
const ENEMY_COLOR := Color("a53030")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")

@export_range(1, 30, 1) var max_rounds: int = 15
@export_range(1, 15, 1) var wins_to_match: int = 8
@export_range(120.0, 520.0, 1.0) var box_width: float = 390.0
@export_range(36.0, 100.0, 1.0) var box_height: float = 58.0
@export_range(0.0, 60.0, 1.0) var screen_margin: float = 15.0
@export_range(0.0, 30.0, 1.0) var row_gap: float = 8.0
@export_range(12.0, 48.0, 1.0) var dot_size: float = 28.0
@export_range(0.2, 1.0, 0.01) var inner_dot_scale: float = 0.72
@export_range(0.0, 60.0, 1.0) var name_dot_gap: float = 12.0
@export_range(0.0, 8.0, 0.1) var appear_delay: float = 3.0
@export_range(0.05, 1.0, 0.01) var appear_duration: float = 0.22
@export_range(1.0, 2.0, 0.01) var match_win_scale: float = 1.22
@export_range(0.05, 1.0, 0.01) var match_win_move_duration: float = 0.35
@export_range(0.05, 1.0, 0.01) var dot_pop_duration: float = 0.16
@export_range(1.0, 1.6, 0.01) var dot_pop_scale: float = 1.18
@export_range(0.0, 40.0, 1.0) var match_buttons_margin: float = 12.0
@export_range(0.0, 60.0, 1.0) var match_buttons_gap: float = 20.0

var score_state: MatchScoreState = MatchScoreState.new()

var _base_box_width: float
var _local_box: Panel
var _enemy_box: Panel
var _local_name: Label
var _enemy_name: Label
var _local_dots: Array[Panel] = []
var _enemy_dots: Array[Panel] = []
var _pending_local_name: String = "Player"
var _pending_enemy_name: String = "Enemy"
var _dot_gap: float = 6.0
var _side_padding: float = 10.0
var _name_width: float = 92.0
var _match_over: bool = false
var _match_over_pending: bool = false
var _match_layer: CanvasLayer
var _match_root: Control
var _winner_name_box: Panel
var _winner_name_label: Label
var _match_dots: Array[Panel] = []
var _restart_button: Button
var _quit_button: Button
var _button_tweens: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_box_width = box_width
	score_state.configure(max_rounds, wins_to_match)
	_build_ui()
	_build_match_over_ui()
	set_names(_pending_local_name, _pending_enemy_name)
	_refresh()
	_play_appear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_position_boxes()


func set_names(local_name: String, enemy_name: String) -> void:
	_pending_local_name = _clean_name(local_name, "Player")
	_pending_enemy_name = _clean_name(enemy_name, "Enemy")
	if not _local_name or not _enemy_name:
		return
	_local_name.text = _pending_local_name
	_enemy_name.text = _pending_enemy_name
	_update_layout_size()


func get_next_marker_position(team: int) -> Vector2:
	var dots: Array[Panel] = _get_dots(team)
	var index: int = score_state.get_next_marker_index(team)
	if index < 0 or index >= dots.size():
		return global_position + size * 0.5
	var dot: Panel = dots[index]
	return dot.global_position + dot.size * 0.5


func add_win(team: int, animate: bool = false) -> void:
	var won_index: int = score_state.add_win(team)
	if won_index < 0:
		return
	_refresh()
	if animate:
		_pop_dot(team, won_index)
	if is_match_over() and not _match_over_pending:
		_match_over_pending = true
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree() or not _match_over_pending:
			return
		_show_match_winner(team)


func is_match_over() -> bool:
	return score_state.is_match_over()


func reset_match() -> void:
	InputModalLock.set_locked(get_tree(), false)
	score_state.reset()
	_match_over = false
	_match_over_pending = false
	set_restart_waiting(false)
	_match_root.hide()
	_local_name.show()
	_enemy_name.show()
	_local_box.show()
	_enemy_box.show()
	_position_boxes()
	_local_box.scale = Vector2.ONE
	_enemy_box.scale = Vector2.ONE
	_resize_box(_local_box)
	_resize_box(_enemy_box)
	_reposition_dots(_local_dots)
	_reposition_dots(_enemy_dots)
	_refresh()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_local_box = _make_box()
	_enemy_box = _make_box()
	add_child(_local_box)
	add_child(_enemy_box)
	_local_box.gui_input.connect(_on_score_box_gui_input.bind(CardSlot.TEAM_PLAYER))
	_enemy_box.gui_input.connect(_on_score_box_gui_input.bind(CardSlot.TEAM_ENEMY))

	_local_name = _build_name(_local_box, PLAYER_COLOR)
	_enemy_name = _build_name(_enemy_box, ENEMY_COLOR)
	_local_name.text = "Player"
	_enemy_name.text = "Enemy"
	_local_dots = _build_dots(_local_box)
	_enemy_dots = _build_dots(_enemy_box)
	_position_boxes()


func _make_box() -> Panel:
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(box_width, box_height)
	panel.size = Vector2(box_width, box_height)
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ZERO
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = LIGHT_COLOR
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _build_name(parent: Panel, name_color: Color) -> Label:
	var name_label: Label = Label.new()
	name_label.position = Vector2(_side_padding, 0.0)
	name_label.size = Vector2(_name_width, box_height)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_override("font", CARD_FONT)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", name_color)
	parent.add_child(name_label)
	return name_label


func _build_dots(parent: Panel) -> Array[Panel]:
	var dots: Array[Panel] = []
	var start_x: float = _side_padding + _name_width + name_dot_gap
	var start_y: float = (box_height - dot_size) * 0.5
	for index in range(wins_to_match):
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2.ONE * dot_size
		dot.size = Vector2.ONE * dot_size
		dot.position = Vector2(start_x + float(index) * (dot_size + _dot_gap), start_y)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", _circle_style(DARK_COLOR))
		parent.add_child(dot)

		var inner: Panel = Panel.new()
		var inner_size: float = dot_size * inner_dot_scale
		inner.name = "Inner"
		inner.size = Vector2.ONE * inner_size
		inner.position = (Vector2.ONE * dot_size - inner.size) * 0.5
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(inner)
		dots.append(dot)
	return dots


func _position_boxes() -> void:
	if not _local_box or not _enemy_box:
		return
	if _match_over:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var x_position: float = viewport_size.x - box_width - screen_margin
	_local_box.position = Vector2(x_position, screen_margin)
	_enemy_box.position = Vector2(x_position, screen_margin + box_height + row_gap)
	_local_box.pivot_offset = _local_box.size * 0.5
	_enemy_box.pivot_offset = _enemy_box.size * 0.5


func _update_layout_size() -> void:
	var font_size: int = 18
	var local_width: float = CARD_FONT.get_string_size(_pending_local_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var enemy_width: float = CARD_FONT.get_string_size(_pending_enemy_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	_name_width = maxf(62.0, maxf(local_width, enemy_width) + 8.0)
	var dots_width: float = dot_size * wins_to_match + _dot_gap * maxi(0, wins_to_match - 1)
	box_width = maxf(_base_box_width, _side_padding * 2.0 + _name_width + name_dot_gap + dots_width)
	_resize_box(_local_box)
	_resize_box(_enemy_box)
	_local_name.size = Vector2(_name_width, box_height)
	_enemy_name.size = Vector2(_name_width, box_height)
	_reposition_dots(_local_dots)
	_reposition_dots(_enemy_dots)
	_position_boxes()


func _resize_box(box: Panel) -> void:
	box.custom_minimum_size = Vector2(box_width, box_height)
	box.size = Vector2(box_width, box_height)


func _reposition_dots(dots: Array[Panel], centered: bool = false) -> void:
	var dots_width: float = dot_size * wins_to_match + _dot_gap * maxi(0, wins_to_match - 1)
	var start_x: float = (box_width - dots_width) * 0.5 if centered else _side_padding + _name_width + name_dot_gap
	var start_y: float = (box_height - dot_size) * 0.5
	for index in range(dots.size()):
		dots[index].position = Vector2(start_x + float(index) * (dot_size + _dot_gap), start_y)


func _play_appear() -> void:
	await get_tree().create_timer(appear_delay).timeout
	if not is_inside_tree():
		return
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_local_box, "scale", Vector2.ONE, appear_duration)
	tween.tween_property(_enemy_box, "scale", Vector2.ONE, appear_duration).set_delay(0.05)


func _refresh() -> void:
	_refresh_dots(_local_dots, score_state.local_score, PLAYER_COLOR)
	_refresh_dots(_enemy_dots, score_state.enemy_score, ENEMY_COLOR)


func _refresh_dots(dots: Array[Panel], score: int, color: Color) -> void:
	for index in range(dots.size()):
		var inner: Panel = dots[index].get_node("Inner") as Panel
		inner.visible = index < score
		inner.add_theme_stylebox_override("panel", _circle_style(color))


func _pop_dot(team: int, index: int) -> void:
	var dots: Array[Panel] = _get_dots(team)
	if index < 0 or index >= dots.size():
		return
	var dot: Panel = dots[index]
	var inner: Panel = dot.get_node("Inner") as Panel
	dot.pivot_offset = dot.size * 0.5
	inner.pivot_offset = inner.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dot, "scale", Vector2.ONE * dot_pop_scale, dot_pop_duration)
	tween.tween_property(inner, "scale", Vector2.ONE * dot_pop_scale, dot_pop_duration)
	tween.chain().tween_property(dot, "scale", Vector2.ONE, dot_pop_duration)
	tween.tween_property(inner, "scale", Vector2.ONE, dot_pop_duration)


func _build_match_over_ui() -> void:
	_match_layer = CanvasLayer.new()
	_match_layer.layer = 300
	add_child(_match_layer)

	_match_root = Control.new()
	_match_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_match_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_match_root.hide()
	_match_layer.add_child(_match_root)

	_winner_name_box = Panel.new()
	_winner_name_box.add_theme_stylebox_override("panel", UIButtonStyle.make_box_style(LIGHT_COLOR))
	_match_root.add_child(_winner_name_box)

	_winner_name_label = Label.new()
	_winner_name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_winner_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_winner_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_winner_name_label.add_theme_font_override("font", CARD_FONT)
	_winner_name_label.add_theme_font_size_override("font_size", 42)
	_winner_name_box.add_child(_winner_name_label)
	_match_dots = _build_match_dots(_winner_name_box)

	_restart_button = _make_button("RESTART")
	_quit_button = _make_button("QUIT")
	_match_root.add_child(_restart_button)
	_match_root.add_child(_quit_button)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _make_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size = Vector2(160.0, 54.0)
	button.pivot_offset = button.size * 0.5
	UIButtonStyle.apply_plain_button(button, 24, LIGHT_COLOR, DARK_COLOR)
	button.resized.connect(_center_button_pivot.bind(button))
	button.mouse_entered.connect(_animate_button.bind(button, true))
	button.mouse_exited.connect(_animate_button.bind(button, false))
	return button


func _build_match_dots(parent: Panel) -> Array[Panel]:
	var dots: Array[Panel] = []
	for index in range(wins_to_match):
		var dot: Panel = Panel.new()
		dot.size = Vector2.ONE * dot_size
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", _circle_style(DARK_COLOR))
		parent.add_child(dot)

		var inner: Panel = Panel.new()
		var inner_size: float = dot_size * inner_dot_scale
		inner.name = "Inner"
		inner.size = Vector2.ONE * inner_size
		inner.position = (Vector2.ONE * dot_size - inner.size) * 0.5
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(inner)
		dots.append(dot)
	return dots


func _reposition_match_dots(panel_width: float, score: int, color: Color) -> void:
	var dots_width: float = dot_size * wins_to_match + _dot_gap * maxi(0, wins_to_match - 1)
	var start_x: float = (panel_width - dots_width) * 0.5
	var start_y: float = 78.0
	for index in range(_match_dots.size()):
		var dot: Panel = _match_dots[index]
		var inner: Panel = dot.get_node("Inner") as Panel
		dot.position = Vector2(start_x + float(index) * (dot_size + _dot_gap), start_y)
		inner.visible = index < score
		inner.add_theme_stylebox_override("panel", _circle_style(color))


func _show_match_winner(team: int) -> void:
	if _match_over:
		return
	_match_over = true
	_match_over_pending = false
	InputModalLock.set_locked(get_tree(), true)
	_match_root.show()
	_match_root.modulate.a = 1.0
	var viewport_size: Vector2 = get_viewport_rect().size
	var score: int = score_state.get_score(team)
	var winner_color: Color = PLAYER_COLOR if team == CardSlot.TEAM_PLAYER else ENEMY_COLOR
	var winner_text: String = "%s won!" % (_pending_local_name if team == CardSlot.TEAM_PLAYER else _pending_enemy_name)
	var dots_width: float = dot_size * wins_to_match + _dot_gap * maxi(0, wins_to_match - 1)
	var text_width: float = CARD_FONT.get_string_size(winner_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 42).x + 48.0
	var panel_width: float = clampf(maxf(text_width, dots_width + 48.0), 360.0, viewport_size.x - screen_margin * 2.0)
	var panel_height: float = 132.0
	var panel_position: Vector2 = (viewport_size - Vector2(panel_width, panel_height)) * 0.5
	_winner_name_label.text = winner_text
	_winner_name_label.add_theme_color_override("font_color", winner_color)
	_winner_name_box.size = Vector2(panel_width, panel_height)
	_winner_name_label.position = Vector2(12.0, 8.0)
	_winner_name_label.size = Vector2(panel_width - 24.0, 54.0)
	_fit_winner_label_font(winner_text, panel_width - 24.0)
	_reposition_match_dots(panel_width, score, winner_color)
	_winner_name_box.position = panel_position
	_winner_name_box.pivot_offset = _winner_name_box.size * 0.5
	_winner_name_box.scale = Vector2.ZERO
	_position_match_buttons(panel_position, Vector2(panel_width, panel_height))
	_restart_button.scale = Vector2.ZERO
	_quit_button.scale = Vector2.ZERO
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var exit_x: float = viewport_size.x + box_width + screen_margin
	tween.tween_property(_local_box, "position:x", exit_x, match_win_move_duration)
	tween.tween_property(_enemy_box, "position:x", exit_x, match_win_move_duration)
	tween.tween_property(_winner_name_box, "scale", Vector2.ONE, match_win_move_duration)
	tween.tween_property(_restart_button, "scale", Vector2.ONE, match_win_move_duration).set_delay(0.12)
	tween.tween_property(_quit_button, "scale", Vector2.ONE, match_win_move_duration).set_delay(0.16)


func _position_match_buttons(panel_position: Vector2, panel_size: Vector2) -> void:
	var group_width: float = _restart_button.size.x + match_buttons_gap + _quit_button.size.x
	var start_x: float = panel_position.x + (panel_size.x - group_width) * 0.5
	var y_position: float = panel_position.y + panel_size.y + match_buttons_margin
	_restart_button.position = Vector2(start_x, y_position)
	_quit_button.position = Vector2(start_x + _restart_button.size.x + match_buttons_gap, y_position)


func _center_button_pivot(button: Button) -> void:
	UIButtonStyle.center_pivot(button)


func _animate_button(button: Button, hovered: bool) -> void:
	UIButtonStyle.animate_hover(self, button, hovered, _button_tweens)


func _fit_winner_label_font(text: String, max_width: float) -> void:
	var font_size: int = 42
	while font_size > 20 and CARD_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x > max_width:
		font_size -= 1
	_winner_name_label.add_theme_font_size_override("font_size", font_size)


func _on_restart_pressed() -> void:
	restart_requested.emit()


func set_restart_waiting(waiting: bool) -> void:
	if not _restart_button:
		return
	_restart_button.text = "WAIT" if waiting else "RESTART"
	UIButtonStyle.set_button_colors(
		_restart_button,
		DARK_COLOR if waiting else LIGHT_COLOR,
		LIGHT_COLOR if waiting else DARK_COLOR
	)


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _on_score_box_gui_input(event: InputEvent, team: int) -> void:
	if _match_over:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_event.shift_pressed:
		return
	add_win(team, true)


func _get_dots(team: int) -> Array[Panel]:
	return _local_dots if team == CardSlot.TEAM_PLAYER else _enemy_dots


func _circle_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(999)
	return style


func _clean_name(value: String, fallback: String) -> String:
	var result: String = value.strip_edges()
	return fallback if result.is_empty() else result
