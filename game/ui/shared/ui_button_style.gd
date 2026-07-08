class_name UIButtonStyle
extends RefCounted

const LIGHT_COLOR := Color("#ebede9")
const DARK_COLOR := Color("#151d28")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")


static func apply_plain_button(button: Button, font_size: int = 24, bg_color: Color = LIGHT_COLOR, text_color: Color = DARK_COLOR) -> StyleBoxFlat:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", CARD_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return set_button_colors(button, bg_color, text_color)


static func set_button_colors(button: Button, bg_color: Color, text_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
	if style == null:
		style = make_box_style(bg_color)
	style.bg_color = bg_color
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, text_color)
	return style


static func make_box_style(color: Color, radius: int = 6) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func center_pivot(control: Control) -> void:
	control.pivot_offset = control.size * 0.5


static func animate_hover(owner: Node, button: Button, hovered: bool, tweens: Dictionary, hover_scale: float = 1.06, duration: float = 0.12) -> void:
	var key: int = button.get_instance_id()
	var old_tween: Tween = tweens.get(key) as Tween
	if old_tween and old_tween.is_valid():
		old_tween.kill()
	var target_scale: Vector2 = Vector2.ONE * (hover_scale if hovered else 1.0)
	var tween: Tween = owner.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, duration)
	tweens[key] = tween
