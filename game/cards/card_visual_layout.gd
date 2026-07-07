class_name CardVisualLayout
extends RefCounted


static func configure(card: CardVisual) -> void:
	card.custom_minimum_size = card.card_size
	card.size = card.card_size
	card.card_surface.size = card.card_size
	card.card_surface.pivot_offset = card.card_size * 0.5

	card.title_box.size = card.title_box_size
	card.title_box.position = (card.card_size - card.title_box_size) * 0.5 + Vector2.DOWN * card.title_box_offset_y
	card.title_label.position = Vector2(card.title_side_margin, 0.0)
	card.title_label.size = Vector2(card.title_box_size.x - card.title_side_margin * 2.0, card.title_box_size.y)
	card.title_label.add_theme_font_size_override("font_size", card.title_font_size)
	card.title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	configure_rarity_panels(card)
	configure_art(card)

	var title_style: StyleBoxFlat = card.title_box.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	title_style.set_corner_radius_all(card.title_box_corner_radius)
	card.title_box.add_theme_stylebox_override("panel", title_style)

	var bottom_y: float = card.card_size.y - card.bottom_stat_size + card.bottom_stat_offset_y
	var description_top: float = card.title_box.position.y + card.title_box.size.y + card.description_top_gap
	var description_bottom: float = minf(
		card.card_size.y - card.description_bottom_margin,
		bottom_y - card.description_stat_gap
	)
	card.description_label.position = Vector2(card.description_side_margin, description_top)
	card.description_label.size = Vector2(
		maxf(0.0, card.card_size.x - card.description_side_margin * 2.0),
		maxf(0.0, description_bottom - description_top)
	)

	var bottom_dimensions: Vector2 = Vector2.ONE * card.bottom_stat_size
	card.attack_stat.size = bottom_dimensions
	card.health_stat.size = bottom_dimensions
	card.attack_stat.position = Vector2(card.bottom_stat_horizontal_inset, bottom_y)
	card.health_stat.position = Vector2(card.card_size.x - card.bottom_stat_size - card.bottom_stat_horizontal_inset, bottom_y)
	card.attack_stat.fill_color = card.attack_color
	card.health_stat.fill_color = card.health_color
	var temporary_attack_size: float = card.bottom_stat_size * card.temporary_attack_stat_scale
	card.temporary_attack_stat.size = Vector2.ONE * temporary_attack_size
	card.temporary_attack_stat.position = Vector2(
		card.attack_stat.position.x + card.bottom_stat_size + card.temporary_attack_stat_margin,
		card.attack_stat.position.y + (card.bottom_stat_size - temporary_attack_size) * 0.5
	)
	card.temporary_attack_stat.fill_color = CardStat.TEMPORARY_ATTACK_COLOR
	var poison_size: float = card.bottom_stat_size * card.poison_stat_scale
	card.poison_stat.size = Vector2.ONE * poison_size
	card.poison_stat.position = Vector2(
		card.health_stat.position.x - poison_size - card.poison_stat_margin,
		card.health_stat.position.y + (card.bottom_stat_size - poison_size) * 0.5
	)
	card.poison_stat.fill_color = CardStat.POISON_COLOR

	card.cooldown_stat.size = Vector2.ONE * card.cooldown_stat_size
	card.cooldown_stat.position = card.cooldown_stat_position
	card.cooldown_stat.fill_color = card.cooldown_stat_color


static func configure_rarity_panels(card: CardVisual) -> void:
	var split_y: float = card.title_box.position.y + card.title_box.size.y * 0.5
	var inner_width: float = card.card_size.x - CardVisual.OUTLINE_WIDTH * 2.0
	card.rarity_top.position = Vector2(CardVisual.OUTLINE_WIDTH, CardVisual.OUTLINE_WIDTH)
	card.rarity_top.size = Vector2(inner_width, maxf(0.0, split_y - CardVisual.OUTLINE_WIDTH))
	card.rarity_bottom.position = Vector2(CardVisual.OUTLINE_WIDTH, split_y)
	card.rarity_bottom.size = Vector2(inner_width, maxf(0.0, card.card_size.y - split_y - CardVisual.OUTLINE_WIDTH))


static func configure_art(card: CardVisual) -> void:
	var data: CardData = card._get_display_data()
	var base_size: Vector2 = Vector2(
		card.card_size.x - card.art_margin * 2.0,
		card.title_box.position.y - card.art_margin * 2.0
	)
	card.art_texture.position = Vector2.ONE * card.art_margin + data.art_offset
	card.art_texture.size = base_size
	card.art_texture.pivot_offset = card.art_texture.size * 0.5
	card.art_texture.scale = Vector2.ONE * data.art_scale


static func apply_rarity(card: CardVisual, rarity: CardData.Rarity) -> void:
	var index: int = clampi(int(rarity), 0, CardVisual.RARITY_BOTTOM_COLORS.size() - 1)
	var top_style: StyleBoxFlat = card.rarity_top.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	top_style.bg_color = CardVisual.RARITY_TOP_COLORS[index]
	card.rarity_top.add_theme_stylebox_override("panel", top_style)
	var bottom_style: StyleBoxFlat = card.rarity_bottom.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	bottom_style.bg_color = CardVisual.RARITY_BOTTOM_COLORS[index]
	card.rarity_bottom.add_theme_stylebox_override("panel", bottom_style)


static func fit_description_text(card: CardVisual) -> void:
	var font: Font = card.description_label.get_theme_font("normal_font")
	var plain_text: String = card._description_plain_text
	var lines: int = max(1, plain_text.count("\n") + 1)
	var smallest: int = mini(card.description_min_font_size, card.description_max_font_size)
	var largest: int = maxi(card.description_min_font_size, card.description_max_font_size)
	for font_size in range(largest, smallest - 1, -1):
		var line_height: float = font.get_height(font_size)
		var total_height: float = line_height * lines
		var max_width: float = 0.0
		for line in plain_text.split("\n"):
			max_width = maxf(max_width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x)
		if total_height <= card.description_label.size.y and max_width <= card.description_label.size.x:
			card.description_label.add_theme_font_size_override("normal_font_size", font_size)
			return
	card.description_label.add_theme_font_size_override("normal_font_size", smallest)


static func fit_title_text(card: CardVisual) -> void:
	var font: Font = card.title_label.get_theme_font("font")
	var smallest: int = mini(card.title_min_font_size, card.title_font_size)
	var largest: int = maxi(card.title_min_font_size, card.title_font_size)
	for font_size in range(largest, smallest - 1, -1):
		var text_width: float = font.get_string_size(card.title_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
		if text_width <= card.title_label.size.x:
			card.title_label.add_theme_font_size_override("font_size", font_size)
			return
	card.title_label.add_theme_font_size_override("font_size", smallest)
