extends VBoxContainer

const CARD_FONT := preload("res://assets/fonts/cardfont.ttf")
const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const TRAIT_COLOR := Color("de9e41")
const CONTENT_WIDTH := 272.0
const PADDING := 12.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 5)
	hide()


func configure(sections: Array[Dictionary]) -> void:
	for child in get_children():
		child.free()
	for section in sections:
		add_child(_create_section(section))
	reset_size()


func _create_section(section: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = LIGHT_COLOR
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = PADDING
	panel_style.content_margin_top = PADDING
	panel_style.content_margin_right = PADDING
	panel_style.content_margin_bottom = PADDING
	panel.add_theme_stylebox_override("panel", panel_style)

	var text_stack := VBoxContainer.new()
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_theme_constant_override("separation", 0)
	panel.add_child(text_stack)

	var title := str(section.get("title", ""))
	var description := str(section.get("description", ""))
	var title_color: Color = section.get("color", TRAIT_COLOR)
	text_stack.add_child(_create_label(title, title_color))
	if not description.is_empty():
		text_stack.add_child(_create_label(description, DARK_COLOR))
	return panel


func _create_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.x = CONTENT_WIDTH
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.add_theme_font_override("font", CARD_FONT)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	return label
