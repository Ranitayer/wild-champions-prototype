class_name NetworkDebugMenu
extends CanvasLayer

const LIGHT_COLOR := Color("#ebede9")
const DARK_COLOR := Color("#151d28")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")

@export var network_manager_path: NodePath = ^"../NetworkManager"
@export var default_port := 24565
@export var menu_width := 360.0
@export var button_height := 54.0
@export var hover_scale := 1.06
@export var hover_duration := 0.12

var _root: Control
var _name_field: LineEdit
var _ip_field: LineEdit
var _port_field: LineEdit
var _status_label: Label
var _host_button: Button
var _join_button: Button
var _button_tweens: Dictionary = {}

@onready var _network_manager: NetworkManager = get_node_or_null(network_manager_path) as NetworkManager


func _ready() -> void:
	add_to_group("network_debug_menus")
	_build_ui()
	_connect_network()
	show()
	_set_status("Host or join. Ctrl+F3 skips.")


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if not visible or not key_event.pressed or key_event.echo:
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_F3:
		_sync_player_name()
		hide()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.color = DARK_COLOR
	_root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(center)

	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(menu_width, 0.0)
	stack.add_theme_constant_override("separation", 12)
	stack.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(stack)

	var title := _make_label("NETWORK", 32)
	stack.add_child(title)

	_name_field = _make_text_field("Player", "NAME")
	_name_field.text_changed.connect(_on_name_changed)
	stack.add_child(_name_field)

	_ip_field = _make_text_field("127.0.0.1", "IP")
	stack.add_child(_ip_field)

	_port_field = _make_text_field(str(default_port), "PORT")
	_port_field.max_length = 5
	stack.add_child(_port_field)

	_host_button = _make_button("HOST")
	_join_button = _make_button("JOIN")
	stack.add_child(_host_button)
	stack.add_child(_join_button)

	_status_label = _make_label("", 18)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_status_label)

	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)


func _connect_network() -> void:
	if _network_manager == null:
		_set_status("NetworkManager missing.")
		return
	_network_manager.connected.connect(_on_network_connected)
	_network_manager.disconnected.connect(_on_network_disconnected)
	_network_manager.connection_failed.connect(_on_connection_failed)


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", CARD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", LIGHT_COLOR)
	return label


func _make_text_field(text: String, placeholder: String) -> LineEdit:
	var field := LineEdit.new()
	field.text = text
	field.placeholder_text = placeholder
	field.custom_minimum_size = Vector2(menu_width, button_height)
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_override("font", CARD_FONT)
	field.add_theme_font_size_override("font_size", 22)
	field.add_theme_color_override("font_color", DARK_COLOR)
	field.add_theme_color_override("caret_color", DARK_COLOR)
	field.add_theme_stylebox_override("normal", _make_box_style(LIGHT_COLOR))
	field.add_theme_stylebox_override("focus", _make_box_style(LIGHT_COLOR))
	return field


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(menu_width, button_height)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", CARD_FONT)
	button.add_theme_font_size_override("font_size", 24)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, DARK_COLOR)
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, _make_box_style(LIGHT_COLOR))
	button.resized.connect(_center_button_pivot.bind(button))
	button.mouse_entered.connect(_animate_button.bind(button, true))
	button.mouse_exited.connect(_animate_button.bind(button, false))
	return button


func _make_box_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _center_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _animate_button(button: Button, hovered: bool) -> void:
	var key := button.get_instance_id()
	var old_tween: Tween = _button_tweens.get(key) as Tween
	if old_tween != null and old_tween.is_valid():
		old_tween.kill()
	var target_scale := Vector2.ONE * (hover_scale if hovered else 1.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, hover_duration)
	_button_tweens[key] = tween


func _on_host_pressed() -> void:
	if _network_manager == null:
		_set_status("NetworkManager missing.")
		return
	_sync_player_name()
	var port: int = _get_port()
	if port == 0:
		return
	var error := _network_manager.host(port)
	if error != OK:
		_set_status("Host failed: %s" % str(error))
		return
	_set_status("Hosting on port %d." % port)


func _on_join_pressed() -> void:
	if _network_manager == null:
		_set_status("NetworkManager missing.")
		return
	_sync_player_name()
	var ip := _ip_field.text.strip_edges()
	if ip.is_empty():
		_set_status("Enter IP.")
		return
	var join_port: int = _get_port()
	if join_port == 0:
		return
	var error := _network_manager.join(ip, join_port)
	if error != OK:
		_set_status("Join failed: %s" % str(error))
		return
	_set_status("Joining %s:%d..." % [ip, join_port])


func _on_network_connected(peer_id: int) -> void:
	if _network_manager.is_host() and peer_id == multiplayer.get_unique_id():
		_set_status("Hosting on port %d." % _get_port())
		return
	_set_status("Connected.")
	hide()


func _on_network_disconnected(_peer_id: int) -> void:
	show()
	_set_status("Other player disconnected.")


func _on_connection_failed() -> void:
	show()
	_set_status("Connection failed.")


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _sync_player_name() -> void:
	if _network_manager:
		_network_manager.set_player_name(_name_field.text)
		_network_manager.send_player_name()


func _on_name_changed(_new_text: String) -> void:
	_sync_player_name()


func _get_port() -> int:
	var port_text: String = _port_field.text.strip_edges()
	if not port_text.is_valid_int():
		_set_status("Enter valid port.")
		return 0
	var port: int = int(port_text)
	if port < 1 or port > 65535:
		_set_status("Port must be 1-65535.")
		return 0
	return port
