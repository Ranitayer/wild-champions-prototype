class_name BoosterPackTooltip
extends Panel

const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const CARD_FONT: FontFile = preload("res://assets/fonts/cardfont.ttf")
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Mythic"]

@export var slots_path: NodePath = ^"../../BottomSlots"
@export_range(0.0, 80.0, 1.0) var slot_margin := 30.0
@export_range(360.0, 900.0, 1.0) var tooltip_width := 640.0
@export_range(4.0, 24.0, 1.0) var padding := 10.0
@export_range(0, 16, 1) var text_line_margin := 2
@export_range(0.05, 0.4, 0.01) var zoom_duration := 0.12
@export_range(0.5, 1.0, 0.01) var start_scale := 0.92

var _text: RichTextLabel
var _tween: Tween
var _show_version := 0

@onready var slots: Control = get_node(slots_path) as Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_style()
	_create_text()
	hide()
	_connect_booster_packs()


func _on_pack_hover_changed(pack: BoosterPack, hovered: bool) -> void:
	_show_version += 1
	if hovered:
		_show_for_pack(pack, _show_version)
	else:
		_hide_with_zoom(_show_version)


func _show_for_pack(pack: BoosterPack, version: int) -> void:
	var data: BoosterPackData = pack.pack_data as BoosterPackData
	if not data:
		hide()
		return
	_text.text = _build_text(data)
	await _fit_to_text()
	if version != _show_version:
		return
	_position_above_slots()
	_show_with_zoom()


func _create_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = LIGHT_COLOR
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)


func _create_text() -> void:
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_color_override("default_color", DARK_COLOR)
	_text.add_theme_font_override("normal_font", CARD_FONT)
	_text.add_theme_font_override("bold_font", CARD_FONT)
	_text.add_theme_font_size_override("normal_font_size", 16)
	_text.add_theme_font_size_override("bold_font_size", 16)
	_text.add_theme_constant_override("line_separation", text_line_margin)
	add_child(_text)


func _build_text(data: BoosterPackData) -> String:
	return "[center][font_size=18][color=#%s]%s[/color][/font_size]\n%s\n%s[/center]" % [
		data.pack_color.to_html(false),
		data.title,
		data.description,
		_build_odds_text(data),
	]


func _build_odds_text(data: BoosterPackData) -> String:
	var odds: Array[String] = []
	var pity_misses: int = _get_pity_misses(data)
	var chances: Array[float] = data.get_effective_chances(pity_misses)
	for rarity_index in range(CardData.Rarity.size()):
		var rarity: int = rarity_index
		var chance: float = chances[rarity]
		if chance <= 0.0:
			continue
		odds.append("[color=#%s]%s:[/color] %s%%" % [
			_rarity_color(rarity),
			RARITY_NAMES[rarity],
			data.format_chance(chance),
		])
	return "  ".join(odds)


func _get_pity_misses(data: BoosterPackData) -> int:
	var shop_random: ShopRandom = get_tree().get_first_node_in_group("shop_random") as ShopRandom
	if not shop_random:
		return 0
	return shop_random.get_booster_pity_misses(data)


func _rarity_color(rarity: int) -> String:
	return CardVisual.RARITY_BOTTOM_COLORS[rarity].to_html(false)


func _fit_to_text() -> void:
	_text.position = Vector2.ONE * padding
	_text.size = Vector2(tooltip_width - padding * 2.0, 1.0)
	_text.fit_content = true
	await get_tree().process_frame
	var text_height: float = maxf(1.0, _text.get_content_height())
	size = Vector2(tooltip_width, text_height + padding * 2.0)
	_text.size = Vector2(tooltip_width - padding * 2.0, text_height)


func _show_with_zoom() -> void:
	_kill_tween()
	pivot_offset = size * 0.5
	scale = Vector2.ONE * start_scale
	modulate.a = 0.0
	show()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, zoom_duration)
	_tween.tween_property(self, "modulate:a", 1.0, zoom_duration)


func _hide_with_zoom(version: int) -> void:
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "scale", Vector2.ONE * start_scale, zoom_duration)
	_tween.tween_property(self, "modulate:a", 0.0, zoom_duration)
	_tween.finished.connect(_finish_hide.bind(version))


func _finish_hide(version: int) -> void:
	if version == _show_version:
		hide()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _position_above_slots() -> void:
	if not slots:
		return
	var slot_rect := slots.get_global_rect()
	global_position = Vector2(
		slot_rect.position.x + (slot_rect.size.x - size.x) * 0.5,
		slot_rect.position.y - size.y - slot_margin
	)


func _connect_booster_packs() -> void:
	for node in get_tree().get_nodes_in_group("booster_packs"):
		var pack: BoosterPack = node as BoosterPack
		if pack and not pack.hover_changed.is_connected(_on_pack_hover_changed):
			pack.hover_changed.connect(_on_pack_hover_changed)
