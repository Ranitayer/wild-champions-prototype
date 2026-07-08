@tool
class_name CardVisual
extends Control

signal drag_started(card: CardVisual)
signal invalid_drop_requested(card: CardVisual)
signal merge_started(card: CardVisual, target: CardVisual)
signal sell_requested(card: CardVisual)
signal slotted(card: CardVisual)
signal stat_changed(card: CardVisual, stat_type: CardStat.Type, delta: int)
signal tier_changed(card: CardVisual, tier: int)
signal hover_changed(card: CardVisual, hovered: bool)

const OUTLINE_WIDTH := 4
const DARK_COLOR := Color("151d28")
const ORANGE_COLOR := Color("ffa500")
const TRAIT_COLOR_HEX := "de9e41"
const TRAIT_COLOR := Color("de9e41")
const DRAG_Z_INDEX := 4096
const COMBAT_Z_INDEX := 2048
const TOOLTIP_CANVAS_LAYER := 102
const CARD_TRAIT_TOOLTIP := preload("res://game/ui/card_trait_tooltip/card_trait_tooltip.gd")
const STAT_SCENE := preload("res://game/cards/stat_circle.tscn")
const TAG_ICON_SCRIPT := preload("res://game/cards/card_tag_icon.gd")
const LIQUID_OUTLINE_SHADER := preload("res://game/effects/shaders/liquid_outline.gdshader")
const DEATH_BURN_SHADER := preload("res://game/cards/shaders/card_death_burn.gdshader")
const TAG_ICON_DIR := "res://assets/icons/tags"
const TIER_INDICATOR_DEFAULT_TOP_MARGIN := 12.0
const TIER_INDICATOR_WITH_PRICE_TOP_MARGIN := 52.0
const RARITY_BOTTOM_COLORS := [
	Color("394a50"),
	Color("25562e"),
	Color("253a5e"),
	Color("402751"),
	Color("752438"),
]
const RARITY_TOP_COLORS := [
	Color("a8b5b2"),
	Color("a8ca58"),
	Color("73bed3"),
	Color("df84a5"),
	Color("ff6e6e"),
]

@export var card_data: CardData:
	set(value):
		card_data = value
		_refresh_card_visual()

@export_group("Editor Preview")
@export var editor_preview_data: CardData:
	set(value):
		editor_preview_data = value
		_refresh_card_visual()
@export_group("")

@export_group("Combat Feedback")
@export_range(0.02, 0.5, 0.01) var hit_duration := 0.12
@export_range(0.0, 40.0, 1.0) var hit_knockback_distance := 12.0
@export_range(0.0, 12.0, 0.5) var hit_rotation_shake_degrees := 4.0
@export_range(0.0, 80.0, 1.0) var attack_impact_margin := 8.0
@export_range(0.0, 25.0, 0.5) var attack_aim_rotation_degrees := 8.0
@export_range(0.05, 1.0, 0.05) var dodge_duration := 0.3
@export_range(0.0, 80.0, 1.0) var dodge_distance := 20.0

@export_group("Survival Feedback")
@export_range(0.1, 2.0, 0.05) var survival_sway_duration := 0.5
@export_range(0.0, 20.0, 0.5) var survival_rotation_degrees := 6.0
@export_range(1.0, 1.5, 0.01) var survival_pop_scale := 1.08

@export_group("Death Effect Feedback")
@export_range(0.1, 2.0, 0.05) var death_effect_windup_duration := 0.6
@export_range(0.0, 3.0, 0.05) var death_effect_hold_duration := 1.0
@export_range(1.0, 1.5, 0.01) var death_effect_scale := 1.2
@export_range(0.0, 80.0, 1.0) var death_effect_lift := 28.0
@export_range(-20.0, 20.0, 0.5) var death_effect_rotation_degrees := 5.0

@export_group("Death Animation")
@export_range(0.1, 2.0, 0.05) var death_animation_duration := 1.0
@export_range(0.0, 120.0, 1.0) var death_animation_distance := 44.0
@export_range(1.0, 1.3, 0.01) var death_animation_scale := 1.08
@export_range(-30.0, 30.0, 0.5) var death_animation_rotation_degrees := 8.0

@export_group("Death Burn Shader")
@export var death_burn_color: Color = TRAIT_COLOR
@export_range(0.0, 1.0, 0.01) var death_burn_size := 0.08
@export_range(0.0, 0.2, 0.001) var death_burn_edge_softness := 0.025
@export_range(0.0, 1.0, 0.01) var death_burn_noise_strength := 0.28
@export_range(0.1, 8.0, 0.1) var death_burn_noise_scale := 1.8
@export_range(-1.0, 1.0, 1.0) var death_burn_direction := 1.0
@export_group("")

@export_group("Tag Icons")
@export_range(0.2, 1.0, 0.05) var tag_circle_scale := 0.7
@export_range(0.0, 20.0, 1.0) var tag_circle_gap := 4.0
@export_range(0.0, 30.0, 1.0) var tag_circle_bottom_margin := 0.0
@export_range(0.0, 20.0, 1.0) var tag_icon_margin := 7.0
@export_range(1.0, 6.0, 1.0) var tag_circle_outline_width := 2.0
@export_group("")

@export_group("Drag Outline")
@export var merge_outline_color := Color("20ed36")
@export var valid_drop_outline_color := Color("81e9e5")
@export_range(0.0, 20.0, 0.5) var merge_outline_width := 6.0
@export_range(0.0, 4.0, 0.05) var merge_outline_edge_feather := 0.25
@export_range(0.0, 20.0, 0.5) var merge_outline_liquid_amplitude := 3.0
@export_range(1.0, 40.0, 0.5) var merge_outline_liquid_frequency := 12.0
@export_range(0.0, 10.0, 0.1) var merge_outline_liquid_speed := 2.0
@export_range(0.0, 24.0, 0.5) var merge_outline_padding := 12.0
@export_range(0.0, 30.0, 0.5) var merge_outline_corner_radius := 9.0
@export_range(0.01, 0.5, 0.01) var merge_outline_show_duration := 0.12
@export_range(0.01, 0.5, 0.01) var merge_outline_hide_duration := 0.1
@export_range(0.5, 1.0, 0.01) var merge_outline_spawn_scale := 0.88
@export_group("")

var hit_shake_distance := 6.0
var hit_shake_count := 3
var hit_flash_duration := 0.08
var hit_orange_duration := 0.10
var survival_sway_count := 4
var dodge_rotation_degrees := 6.0
var card_size := CardMetrics.SIZE
var art_margin := 8.0
var hover_scale := 1.4
var hover_lift := 24.0
var hover_duration := 0.22
var release_duration := 0.12
var drag_pickup_zoom_bonus := 0.1
var drag_pickup_sway := 3.0
var drag_max_sway := 8.0
var drag_sway_sensitivity := 0.35
var drag_sway_response := 18.0
var drag_sway_return_speed := 45.0
var snap_duration := 0.18
var attack_anticipation_distance := 24.0
var attack_anticipation_duration := 0.18
var attack_charge_duration := 0.14
var attack_return_duration := 0.22
var attack_scale := 1.1
var title_box_size := Vector2(207.0, 50.0)
var title_box_offset_y := 10.0
var title_box_corner_radius := 6
var title_font_size := 20
var title_min_font_size := 14
var title_side_margin := 12.0
var description_side_margin := 12.0
var description_top_gap := 2.0
var description_bottom_margin := 28.0
var description_stat_gap := 4.0
var description_min_font_size := 10
var description_max_font_size := 18
var bottom_stat_size := 55.0
var bottom_stat_horizontal_inset := -10.0
var bottom_stat_offset_y := 15.0
var attack_color := Color("4f8fba")
var health_color := Color("a53030")
var cooldown_stat_size := 55.0
var cooldown_stat_position := Vector2(-12.0, -12.0)
var cooldown_stat_color := DARK_COLOR
var poison_stat_scale := 0.9
var poison_stat_margin := 4.0
var temporary_attack_stat_scale := 0.9
var temporary_attack_stat_margin := 4.0

@onready var card_surface: Panel = %CardSurface
@onready var merge_animator: CardMergeAnimator = %MergeAnimator
@onready var visual_group: CanvasGroup = %VisualGroup
@onready var rarity_top: Panel = %RarityTop
@onready var rarity_bottom: Panel = %RarityBottom
@onready var art_texture: TextureRect = %ArtTexture
@onready var tier_indicator: CardTierIndicator = %TierIndicator
@onready var title_box: Panel = %TitleBox
@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var attack_stat: StatCircle = %AttackStat
@onready var temporary_attack_stat: StatCircle = %TemporaryAttackStat
@onready var health_stat: StatCircle = %HealthStat
@onready var poison_stat: StatCircle = %PoisonStat
@onready var cooldown_stat: StatCircle = %CooldownStat

var _motion_tween: Tween
var _sway_tween: Tween
var _flash_tween: Tween
var _buff_tween: Tween
var _hit_flash_material: ShaderMaterial
var _death_burn_material: ShaderMaterial
var _death_animation_active := false
var _death_animation_done := false
var _hovered := false
var _dragging := false
var _snapping := false
var _drag_offset := Vector2.ZERO
var _drag_tilt_target := 0.0
var _pickup_sway_active := false
var _current_slot: CardSlot
var _interaction_blocked := false
var _tooltip_hover_while_blocked := false
var _tier_cycle_shortcut_enabled := false
var _resting_z_index := 0
var attack_start_position := Vector2.ZERO
var attack_start_z_index := 0
var attack_returning := false
var _suppress_stat_changes := false
var _description_plain_text := ""
var _trait_tooltip
var _trait_tooltip_layer: CanvasLayer
var _base_tooltip_sections: Array[Dictionary] = []
var _runtime_trait_sections: Dictionary = {}
var _extra_hover_controls: Array[Control] = []
var _drag_guard: Callable
var _card_tier := 1
var _sell_price_stat: StatCircle
var _editor_preview_signature := ""
var _tag_circles: Array[Control] = []
var _merge_outline_material: ShaderMaterial
var _merge_outline_rect: ColorRect
var _merge_outline_tween: Tween
var _merge_outline_visible := false
var _effect_outline_locked := false

static var _last_hover_z_index := 0
static var _tag_icon_cache: Dictionary = {}


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		set_process(true)
		call_deferred("_refresh_card_visual")


func _ready() -> void:
	_configure_feedback_materials()
	visual_group.fit_margin = bottom_stat_size + cooldown_stat_size
	_ensure_tag_icons()
	_configure_layout()
	_apply_data()
	if Engine.is_editor_hint():
		return
	add_to_group("card_visuals")
	_configure_trait_tooltip()
	card_surface.gui_input.connect(_gui_input)
	title_box.gui_input.connect(_gui_input)
	attack_stat.gui_input.connect(_gui_input)
	temporary_attack_stat.gui_input.connect(_gui_input)
	health_stat.gui_input.connect(_gui_input)
	poison_stat.gui_input.connect(_gui_input)
	cooldown_stat.gui_input.connect(_gui_input)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_card_visual_if_changed()
		return
	_update_hover_state()
	_update_trait_tooltip_visibility()
	_update_trait_tooltip_position()
	if _dragging:
		_update_merge_outline_target()
	elif not _effect_outline_locked:
		_clear_merge_outline_target()
	if not _dragging or _pickup_sway_active:
		return
	var response := 1.0 - exp(-drag_sway_response * delta)
	card_surface.rotation_degrees = lerpf(card_surface.rotation_degrees, _drag_tilt_target, response)
	_drag_tilt_target = move_toward(_drag_tilt_target, 0.0, drag_sway_return_speed * delta)


func _update_hover_state() -> void:
	var mouse_position := get_global_mouse_position()
	var hovering_now := _can_hover_tooltip() and _is_top_card_at(mouse_position)
	if hovering_now == _hovered:
		return
	if hovering_now:
		_on_mouse_entered()
	else:
		_on_mouse_exited()


func _unhandled_input(event: InputEvent) -> void:
	CardVisualInput.handle_unhandled_input(self, event)


func _gui_input(event: InputEvent) -> void:
	CardVisualInput.handle_gui_input(self, event)


func _try_start_drag(event: InputEvent) -> bool:
	if _interaction_blocked or _dragging:
		return false
	var mouse_button := event as InputEventMouseButton
	if not mouse_button or mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return false
	if not _is_top_card_at(get_global_mouse_position()):
		return false
	if _tier_cycle_shortcut_enabled and mouse_button.shift_pressed:
		set_card_tier(_card_tier % card_data.get_max_tier() + 1)
		return true
	if _drag_guard.is_valid() and not bool(_drag_guard.call()):
		return true
	_start_drag()
	return true


func set_interaction_blocked(blocked: bool, allow_tooltip_hover := false) -> void:
	var was_hovered := _hovered
	_interaction_blocked = blocked
	_tooltip_hover_while_blocked = blocked and allow_tooltip_hover
	if blocked and not _tooltip_hover_while_blocked and _hovered:
		_on_mouse_exited()
	elif not blocked and was_hovered:
		_hovered = false


func set_current_slot(slot: CardSlot) -> void:
	_current_slot = slot


func get_current_slot() -> CardSlot:
	return _current_slot


func enable_tier_cycle_shortcut() -> void:
	_tier_cycle_shortcut_enabled = true


func disable_tier_cycle_shortcut() -> void:
	_tier_cycle_shortcut_enabled = false


func _can_hover_tooltip() -> bool:
	return not _interaction_blocked or _tooltip_hover_while_blocked


func _is_top_card_at(point: Vector2) -> bool:
	var top_card: CardVisual = null
	for node in get_tree().get_nodes_in_group("card_visuals"):
		var card := node as CardVisual
		if not card or not card._can_hover_tooltip() or not card.is_visible_in_tree():
			continue
		if not card._contains_visual_point(point):
			continue
		if not top_card or card.z_index > top_card.z_index:
			top_card = card
		elif card.z_index == top_card.z_index and card.is_greater_than(top_card):
			top_card = card
	return top_card == self


func _contains_visual_point(point: Vector2) -> bool:
	for node in [self, card_surface, title_box, attack_stat, temporary_attack_stat, health_stat, poison_stat, cooldown_stat]:
		var control := node as Control
		if control.get_global_rect().has_point(point):
			return true
	for circle in _tag_circles:
		if circle.visible and circle.get_global_rect().has_point(point):
			return true
	for control in _extra_hover_controls:
		if is_instance_valid(control) and control.get_global_rect().has_point(point):
			return true
	return false


func add_hover_control(control: Control) -> void:
	if control and not _extra_hover_controls.has(control):
		_extra_hover_controls.append(control)


func remove_hover_control(control: Control) -> void:
	_extra_hover_controls.erase(control)


func show_sell_price(price: int, fill_color: Color) -> void:
	if not is_node_ready() or not card_surface:
		return
	if not _sell_price_stat:
		_sell_price_stat = STAT_SCENE.instantiate() as StatCircle
		_sell_price_stat.size = Vector2.ONE * cooldown_stat_size
		_sell_price_stat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_surface.add_child(_sell_price_stat)
	add_hover_control(_sell_price_stat)
	_sell_price_stat.value = price
	_sell_price_stat.fill_color = fill_color
	_sell_price_stat.position = Vector2(card_size.x - cooldown_stat_size + 12.0, -12.0)
	_sell_price_stat.show()
	tier_indicator.top_margin = TIER_INDICATOR_WITH_PRICE_TOP_MARGIN


func hide_sell_price() -> void:
	if _sell_price_stat:
		remove_hover_control(_sell_price_stat)
		_sell_price_stat.hide()
		tier_indicator.top_margin = TIER_INDICATOR_DEFAULT_TOP_MARGIN


func _ensure_tag_icons() -> void:
	var clean_tags: Array[Control] = []
	for node in _tag_circles:
		if node == null:
			continue
		if not (node is CardTagIcon):
			node.queue_free()
			continue
		clean_tags.append(node)
	_tag_circles = clean_tags
	while _tag_circles.size() < 2:
		var circle: CardTagIcon = TAG_ICON_SCRIPT.new() as CardTagIcon
		circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_surface.add_child(circle)
		_tag_circles.append(circle)


func _layout_tag_icons() -> void:
	if _tag_circles.is_empty():
		return
	var circle_size: float = bottom_stat_size * tag_circle_scale
	var visible_count: int = 0
	for circle in _tag_circles:
		if circle.visible:
			visible_count += 1
	if visible_count == 0:
		visible_count = _tag_circles.size()
	var total_width: float = circle_size * visible_count + tag_circle_gap * max(0, visible_count - 1)
	var start_x: float = (card_size.x - total_width) * 0.5
	var y: float = card_size.y - circle_size - tag_circle_bottom_margin - OUTLINE_WIDTH
	var visible_index: int = 0
	for index in range(_tag_circles.size()):
		var circle: CardTagIcon = _tag_circles[index] as CardTagIcon
		if circle == null:
			continue
		if not circle.visible and visible_count != _tag_circles.size():
			continue
		circle.size = Vector2.ONE * circle_size
		circle.position = Vector2(start_x + visible_index * (circle_size + tag_circle_gap), y)
		circle.icon_margin = tag_icon_margin
		circle.outline_width = tag_circle_outline_width
		visible_index += 1


func _apply_tags(data: CardData) -> void:
	_ensure_tag_icons()
	var icon_index: int = 0
	for tag in data.tags:
		if icon_index >= _tag_circles.size():
			break
		var texture: Texture2D = _get_tag_icon(tag)
		if not texture:
			continue
		var circle: CardTagIcon = _tag_circles[icon_index] as CardTagIcon
		if circle == null:
			continue
		circle.icon_texture = texture
		circle.show()
		icon_index += 1
	for index in range(icon_index, _tag_circles.size()):
		var circle: CardTagIcon = _tag_circles[index] as CardTagIcon
		if circle == null:
			continue
		circle.icon_texture = null
		circle.hide()
	_layout_tag_icons()


func _update_merge_outline_target() -> void:
	var target: CardVisual = _find_merge_target()
	if target != null and _should_show_merge_outline_for(target):
		_show_merge_outline(merge_outline_color)
		return
	if _is_over_valid_drop_destination():
		_show_merge_outline(valid_drop_outline_color)
		return
	_clear_merge_outline_target()


func _clear_merge_outline_target() -> void:
	_hide_merge_outline()


func show_effect_outline(outline_color: Color, show_duration: float) -> void:
	_effect_outline_locked = true
	_show_merge_outline(outline_color, show_duration)


func clear_effect_outline() -> void:
	_effect_outline_locked = false
	_hide_merge_outline()


func _should_show_merge_outline_for(target: CardVisual) -> bool:
	return not target.has_meta("collection_entry_id")


func _show_merge_outline(outline_color: Color, show_duration: float = -1.0) -> void:
	_ensure_merge_outline()
	if _merge_outline_rect == null or _merge_outline_material == null:
		return
	var was_visible: bool = _merge_outline_visible
	var padding: float = maxf(0.0, merge_outline_padding)
	var canvas_size: Vector2 = card_size + Vector2.ONE * padding * 2.0
	_merge_outline_rect.position = -Vector2.ONE * padding
	_merge_outline_rect.size = canvas_size
	_merge_outline_rect.pivot_offset = canvas_size * 0.5
	_apply_merge_outline_parameters(_merge_outline_material, canvas_size, outline_color)
	if was_visible and _merge_outline_rect.visible:
		return
	_merge_outline_visible = true
	_kill_merge_outline_tween()
	if not _merge_outline_rect.visible:
		_merge_outline_rect.scale = Vector2.ONE * merge_outline_spawn_scale
		_merge_outline_rect.modulate.a = 0.0
		_merge_outline_rect.show()
	var duration: float = merge_outline_show_duration if show_duration < 0.0 else show_duration
	_merge_outline_tween = create_tween().set_parallel(true)
	_merge_outline_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_merge_outline_tween.tween_property(_merge_outline_rect, "scale", Vector2.ONE, duration)
	_merge_outline_tween.tween_property(_merge_outline_rect, "modulate:a", 1.0, duration)
	_merge_outline_tween.finished.connect(_on_merge_outline_show_finished)


func _ensure_merge_outline() -> void:
	if _merge_outline_rect:
		return
	_merge_outline_material = ShaderMaterial.new()
	_merge_outline_material.shader = LIQUID_OUTLINE_SHADER
	_merge_outline_rect = ColorRect.new()
	_merge_outline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_merge_outline_rect.color = Color.WHITE
	_merge_outline_rect.show_behind_parent = true
	_merge_outline_rect.z_index = -1
	_merge_outline_rect.material = _merge_outline_material
	card_surface.add_child(_merge_outline_rect)
	_merge_outline_rect.hide()


func _hide_merge_outline() -> void:
	if _merge_outline_rect == null or not _merge_outline_visible:
		return
	_merge_outline_visible = false
	_kill_merge_outline_tween()
	_merge_outline_tween = create_tween().set_parallel(true)
	_merge_outline_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_merge_outline_tween.tween_property(
		_merge_outline_rect,
		"scale",
		Vector2.ONE * merge_outline_spawn_scale,
		merge_outline_hide_duration
	)
	_merge_outline_tween.tween_property(_merge_outline_rect, "modulate:a", 0.0, merge_outline_hide_duration)
	_merge_outline_tween.finished.connect(_on_merge_outline_hide_finished)


func _kill_merge_outline_tween() -> void:
	if _merge_outline_tween == null:
		return
	_merge_outline_tween.kill()
	_merge_outline_tween = null


func _on_merge_outline_show_finished() -> void:
	if _merge_outline_visible:
		_merge_outline_tween = null


func _on_merge_outline_hide_finished() -> void:
	if _merge_outline_visible or _merge_outline_rect == null:
		return
	_merge_outline_rect.hide()
	_merge_outline_rect.scale = Vector2.ONE
	_merge_outline_rect.modulate.a = 1.0
	_merge_outline_tween = null


func _apply_merge_outline_parameters(shader_material: ShaderMaterial, canvas_size: Vector2, outline_color: Color) -> void:
	shader_material.set_shader_parameter("canvas_size", canvas_size)
	shader_material.set_shader_parameter("card_size", card_size)
	shader_material.set_shader_parameter("outline_color", outline_color)
	shader_material.set_shader_parameter("corner_radius", merge_outline_corner_radius)
	shader_material.set_shader_parameter("outline_width", merge_outline_width)
	shader_material.set_shader_parameter("edge_feather", merge_outline_edge_feather)
	shader_material.set_shader_parameter("liquid_amplitude", merge_outline_liquid_amplitude)
	shader_material.set_shader_parameter("liquid_frequency", merge_outline_liquid_frequency)
	shader_material.set_shader_parameter("liquid_speed", merge_outline_liquid_speed)


static func _get_tag_icon(tag: StringName) -> Texture2D:
	var key: String = String(tag)
	if _tag_icon_cache.has(key):
		return _tag_icon_cache[key] as Texture2D
	var texture: Texture2D = load("%s/%s.png" % [TAG_ICON_DIR, key]) as Texture2D
	_tag_icon_cache[key] = texture
	return texture


func set_drag_guard(guard: Callable) -> void:
	_drag_guard = guard


func clear_drag_guard() -> void:
	_drag_guard = Callable()


func _input(event: InputEvent) -> void:
	CardVisualInput.handle_drag_input(self, event)


func _configure_layout() -> void:
	CardVisualLayout.configure(self)


func _configure_rarity_panels() -> void:
	CardVisualLayout.configure_rarity_panels(self)


func _configure_art() -> void:
	CardVisualLayout.configure_art(self)


func _apply_data() -> void:
	var data := _get_display_data()
	tier_indicator.max_tier = data.get_max_tier()
	_card_tier = clampi(data.tier, 1, data.get_max_tier())
	title_label.text = data.title
	_fit_title_text()
	_apply_description(data)
	_apply_tags(data)
	art_texture.texture = data.art
	tier_indicator.tier = _card_tier
	attack_stat.value = data.get_attack(_card_tier)
	health_stat.value = data.get_health(_card_tier)
	cooldown_stat.value = data.cooldown
	_apply_rarity(data.rarity)
	_fit_description_text()


func _get_display_data() -> CardData:
	if card_data:
		return card_data
	if Engine.is_editor_hint() and editor_preview_data:
		return editor_preview_data
	return CardData.new()


func _refresh_card_visual() -> void:
	if not is_inside_tree() or not is_node_ready():
		return
	_configure_layout()
	_apply_data()


func _refresh_card_visual_if_changed() -> void:
	var signature := _make_editor_preview_signature()
	if signature == _editor_preview_signature:
		return
	_editor_preview_signature = signature
	_refresh_card_visual()


func _make_editor_preview_signature() -> String:
	var data := _get_display_data()
	var parts := PackedStringArray([
		str(title_side_margin),
		data.resource_path,
		data.title,
		data.description,
		str(data.art),
		str(data.art_scale),
		str(data.art_offset),
		str(data.rarity),
		str(data.tier),
		str(data.attack),
		str(data.health),
		str(data.cooldown),
		str(data.traits.size()),
		str(data.tags),
		str(tag_circle_scale),
		str(tag_circle_gap),
		str(tag_circle_bottom_margin),
		str(tag_icon_margin),
		str(tag_circle_outline_width),
	])
	return "|".join(parts)


func _apply_description(data: CardData) -> void:
	var trait_lines: Array[String] = []
	for section in _get_trait_sections(data):
		trait_lines.append(str(section.get("title", "")))
	var trait_text := " . ".join(trait_lines)
	var tier_description := data.get_description(_card_tier)
	_description_plain_text = trait_text
	if not tier_description.is_empty():
		_description_plain_text += ("\n" if not _description_plain_text.is_empty() else "") + tier_description

	var parts: Array[String] = []
	if not trait_text.is_empty():
		parts.append("[color=#%s]%s[/color]" % [TRAIT_COLOR_HEX, trait_text])
	if not tier_description.is_empty():
		parts.append(tier_description)
	description_label.text = "[center]%s[/center]" % "\n".join(parts)


func _configure_trait_tooltip() -> void:
	if not card_data:
		return
	_base_tooltip_sections = _get_trait_sections(card_data)
	_refresh_trait_tooltip()


func _get_trait_sections(data: CardData) -> Array[Dictionary]:
	var sections_by_id: Dictionary = {}
	var order: Array[String] = []
	for trait_resource in data.get_traits(_card_tier):
		var trait_definition := trait_resource as CardTrait
		if trait_definition:
			var trait_id := str(trait_definition.trait_id)
			if not sections_by_id.has(trait_id):
				order.append(trait_id)
			sections_by_id[trait_id] = {
				"title": trait_definition.get_display_text(),
				"description": trait_definition.get_tooltip_description(),
				"color": TRAIT_COLOR,
			}
	for runtime_trait_key in _runtime_trait_sections:
		var trait_id := str(runtime_trait_key)
		if not sections_by_id.has(trait_id):
			order.append(trait_id)
		sections_by_id[trait_id] = _runtime_trait_sections[trait_id]
	var sections: Array[Dictionary] = []
	for trait_id in order:
		sections.append(sections_by_id[trait_id])
	return sections


func set_runtime_trait(trait_id: String, title: String, description: String, color: Color = TRAIT_COLOR) -> void:
	if trait_id.is_empty():
		return
	_runtime_trait_sections[trait_id] = {
		"title": title,
		"description": description,
		"color": color,
	}
	var data := _get_display_data()
	_apply_description(data)
	_fit_description_text()
	_configure_trait_tooltip()


func _refresh_trait_tooltip() -> void:
	var sections: Array[Dictionary] = _base_tooltip_sections.duplicate()
	if temporary_attack_stat.value > 0:
		sections.append({
			"title": "Temporary Damage +%d" % temporary_attack_stat.value,
			"description": "Extra attack damage on the next attack.",
			"color": CardStat.TEMPORARY_ATTACK_COLOR,
		})
	if poison_stat.value > 0:
		sections.append({
			"title": "Poisoned",
			"description": "Takes +%d extra damage after being attacked." % poison_stat.value,
			"color": CardStat.POISON_FEEDBACK_COLOR,
		})
	if sections.is_empty():
		if _trait_tooltip_layer:
			_trait_tooltip_layer.queue_free()
			_trait_tooltip_layer = null
			_trait_tooltip = null
		return
	if not _trait_tooltip:
		_trait_tooltip_layer = CanvasLayer.new()
		_trait_tooltip_layer.layer = TOOLTIP_CANVAS_LAYER
		add_child(_trait_tooltip_layer)
		_trait_tooltip = CARD_TRAIT_TOOLTIP.new()
		_trait_tooltip_layer.add_child(_trait_tooltip)
	_trait_tooltip.configure(sections)


func _update_trait_tooltip_position() -> void:
	if not _trait_tooltip or not _trait_tooltip.visible:
		return
	var top_left := card_surface.get_global_transform() * Vector2.ZERO
	var top_right := card_surface.get_global_transform() * Vector2(card_size.x, 0.0)
	_trait_tooltip.global_position = Vector2(
		maxf(top_left.x, top_right.x) + 10.0,
		minf(top_left.y, top_right.y)
	)


func _update_trait_tooltip_visibility() -> void:
	if _trait_tooltip:
		_trait_tooltip.visible = _hovered and not _dragging and _can_hover_tooltip()


func get_card_center() -> Vector2:
	return global_position + card_size * 0.5


func get_card_tier() -> int:
	return _card_tier


func set_card_tier(value: int) -> void:
	var max_tier := card_data.get_max_tier() if card_data else CardData.MAX_TIER
	var next_tier := clampi(value, 1, max_tier)
	if next_tier == _card_tier:
		return
	_card_tier = next_tier
	tier_indicator.tier = _card_tier
	_apply_tier_data()
	tier_changed.emit(self, _card_tier)


func _apply_tier_data() -> void:
	if not card_data:
		return
	var was_suppressing := _suppress_stat_changes
	_suppress_stat_changes = true
	set_attack_value(card_data.get_attack(_card_tier))
	set_health_value(card_data.get_health(_card_tier))
	_apply_description(card_data)
	_fit_description_text()
	_configure_trait_tooltip()
	_suppress_stat_changes = was_suppressing


func can_merge_with(other: CardVisual) -> bool:
	if not is_instance_valid(other) or other == self:
		return false
	if _card_tier != other._card_tier:
		return false
	if not card_data or not other.card_data:
		return false
	if _card_tier >= card_data.get_max_tier() or _card_tier >= other.card_data.get_max_tier():
		return false
	if card_data == other.card_data:
		return true
	return not card_data.resource_path.is_empty() and card_data.resource_path == other.card_data.resource_path


func prepare_for_merge() -> void:
	_effect_outline_locked = false
	_clear_merge_outline_target()
	_stop_tweens()
	_hovered = false
	_dragging = false
	_snapping = true
	set_interaction_blocked(true)
	if _trait_tooltip:
		_trait_tooltip.hide()


func finish_merge(resting_z: int) -> void:
	_snapping = false
	_resting_z_index = resting_z
	z_index = resting_z
	card_surface.position = Vector2.ZERO
	card_surface.scale = Vector2.ONE
	card_surface.rotation_degrees = 0.0
	set_interaction_blocked(false)


func get_card_effect_parent() -> Control:
	return self


func get_card_effect_position() -> Vector2:
	return _get_visual_bounds().position


func get_card_effect_size() -> Vector2:
	return _get_visual_bounds().size


func get_card_effect_mask_data() -> Dictionary:
	var bounds := _get_visual_bounds()
	return {
		"card_rect": Rect2(-bounds.position, card_size),
		"card_radius": 9.0,
		"title_rect": Rect2(title_box.position - bounds.position, title_box.size),
		"title_radius": float(title_box_corner_radius),
		"attack_circle": _get_effect_circle(attack_stat, bounds),
		"temporary_attack_circle": _get_effect_circle(temporary_attack_stat, bounds) if temporary_attack_stat.visible else Vector3(0.0, 0.0, -1.0),
		"health_circle": _get_effect_circle(health_stat, bounds),
		"poison_circle": _get_effect_circle(poison_stat, bounds) if poison_stat.visible else Vector3(0.0, 0.0, -1.0),
		"cooldown_circle": _get_effect_circle(cooldown_stat, bounds),
	}


func _get_effect_circle(stat: Control, bounds: Rect2) -> Vector3:
	return Vector3(
		stat.position.x + stat.size.x * 0.5 - bounds.position.x,
		stat.position.y + stat.size.y * 0.5 - bounds.position.y,
		maxf(stat.size.x, stat.size.y) * 0.5
	)


func _get_visual_bounds() -> Rect2:
	var min_point := Vector2.ZERO
	var max_point := card_size
	for node in [title_box, attack_stat, health_stat, cooldown_stat]:
		var control := node as Control
		min_point.x = minf(min_point.x, control.position.x)
		min_point.y = minf(min_point.y, control.position.y)
		max_point.x = maxf(max_point.x, control.position.x + control.size.x)
		max_point.y = maxf(max_point.y, control.position.y + control.size.y)
	return Rect2(min_point, max_point - min_point)


func get_stat_center(stat_type: CardStat.Type) -> Vector2:
	var stat := _get_stat_control(stat_type)
	return stat.get_global_transform() * (stat.size * 0.5)


func get_stat_size(stat_type: CardStat.Type) -> Vector2:
	return _get_stat_control(stat_type).size


func get_stat_popup_anchor(stat_type: CardStat.Type) -> Vector2:
	var stat := _get_stat_control(stat_type)
	if stat_type == CardStat.Type.COOLDOWN:
		return stat.get_global_transform() * Vector2(0.0, stat.size.y * 0.5)
	return stat.get_global_transform() * Vector2(stat.size.x * 0.5, stat.size.y)


func _get_stat_control(stat_type: CardStat.Type) -> StatCircle:
	match stat_type:
		CardStat.Type.HEALTH:
			return health_stat
		CardStat.Type.COOLDOWN:
			return cooldown_stat
		CardStat.Type.POISON:
			return poison_stat
		CardStat.Type.TEMPORARY_ATTACK:
			return temporary_attack_stat
		_:
			return attack_stat


func play_buff_windup(shrink_scale: float, duration: float) -> void:
	if _buff_tween:
		_buff_tween.kill()
	_buff_tween = create_tween()
	_buff_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_buff_tween.tween_property(card_surface, "scale", Vector2.ONE * shrink_scale, duration)
	await _buff_tween.finished


func start_buff_recovery(duration: float) -> void:
	if _buff_tween:
		_buff_tween.kill()
	_buff_tween = create_tween()
	_buff_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_buff_tween.tween_property(card_surface, "scale", Vector2.ONE, duration)


func is_buff_animating() -> bool:
	return _buff_tween != null and _buff_tween.is_running()


func set_attack_value(value: int) -> void:
	_set_stat_value(attack_stat, CardStat.Type.ATTACK, value)


func set_temporary_attack_value(value: int, show_popup := true) -> void:
	_set_stat_value(temporary_attack_stat, CardStat.Type.TEMPORARY_ATTACK, value, show_popup)
	temporary_attack_stat.visible = temporary_attack_stat.value > 0
	_refresh_trait_tooltip()


func set_health_value(value: int) -> void:
	_set_stat_value(health_stat, CardStat.Type.HEALTH, value)


func set_cooldown_value(value: int, show_popup := true) -> void:
	_set_stat_value(cooldown_stat, CardStat.Type.COOLDOWN, value, show_popup)


func set_poison_value(value: int, show_popup := true) -> void:
	_set_stat_value(poison_stat, CardStat.Type.POISON, value, show_popup)
	poison_stat.visible = poison_stat.value > 0
	_refresh_trait_tooltip()


func _set_stat_value(stat: StatCircle, stat_type: CardStat.Type, value: int, show_popup := true) -> void:
	var normalized_value := value if stat_type == CardStat.Type.HEALTH else maxi(0, value)
	var delta := normalized_value - stat.value
	stat.value = normalized_value
	if delta != 0 and show_popup and not _suppress_stat_changes:
		stat_changed.emit(self, stat_type, delta)


func reset_combat_visuals() -> void:
	clear_effect_outline()
	_stop_tweens()
	_suppress_stat_changes = true
	_runtime_trait_sections.clear()
	_hovered = false
	_dragging = false
	_snapping = false
	_death_animation_active = false
	_death_animation_done = false
	self_modulate = Color.WHITE
	CardVisualCombatFeedback.clear_death_burn_materials(self)
	_set_hit_flash_strength(0.0)
	card_surface.position = Vector2.ZERO
	card_surface.scale = Vector2.ONE
	card_surface.rotation_degrees = 0.0
	set_attack_value(card_data.get_attack(_card_tier) if card_data else 0)
	set_temporary_attack_value(0, false)
	set_health_value(card_data.get_health(_card_tier) if card_data else 0)
	set_cooldown_value(maxi(1, card_data.cooldown) if card_data else 1)
	set_poison_value(0, false)
	if card_data:
		_apply_description(card_data)
		_fit_description_text()
		_configure_trait_tooltip()
	_suppress_stat_changes = false


func play_attack_to_impact(target_center: Vector2) -> void:
	await CardVisualCombatFeedback.play_attack_to_impact(self, target_center)


func start_attack_return() -> void:
	CardVisualCombatFeedback.start_attack_return(self)


func is_attack_returning() -> bool:
	return attack_returning


func _on_attack_return_finished() -> void:
	attack_returning = false
	z_index = attack_start_z_index


func play_hit_animation(attacker_center: Vector2, accent_color: Color = ORANGE_COLOR) -> void:
	var hit_tween := start_hit_animation(attacker_center, accent_color)
	await hit_tween.finished


func start_hit_animation(attacker_center: Vector2, accent_color: Color = ORANGE_COLOR) -> Tween:
	return CardVisualCombatFeedback.start_hit_animation(self, attacker_center, accent_color)


func play_death_effect_windup(effect_color: Color) -> void:
	await CardVisualCombatFeedback.play_death_effect_windup(self, effect_color)


func play_death_animation(fly_direction: Vector2) -> void:
	if _death_animation_done:
		return
	if _death_animation_active:
		while _death_animation_active and is_instance_valid(self):
			await get_tree().process_frame
		return
	_death_animation_active = true
	await CardVisualCombatFeedback.play_death_animation(self, fly_direction)
	hide()
	_death_animation_active = false
	_death_animation_done = true


func play_dissolve_animation() -> void:
	if _death_animation_done:
		return
	if _death_animation_active:
		while _death_animation_active and is_instance_valid(self):
			await get_tree().process_frame
		return
	_death_animation_active = true
	await CardVisualCombatFeedback.play_dissolve_animation(self)
	hide()
	_death_animation_active = false
	_death_animation_done = true


func play_sell_drop(target_global_position: Vector2) -> void:
	await CardVisualCombatFeedback.play_sell_drop(self, target_global_position)


func play_survival_animation() -> void:
	await CardVisualCombatFeedback.play_survival_animation(self)


func play_dodge_animation(direction: float) -> void:
	await CardVisualCombatFeedback.play_dodge_animation(self, direction)


func _flash_hit() -> void:
	CardVisualCombatFeedback.flash_hit(self)


func _set_hit_flash_color(color: Color) -> void:
	CardVisualCombatFeedback.set_hit_flash_color(self, color)


func _set_hit_flash_strength(strength: float) -> void:
	CardVisualCombatFeedback.set_hit_flash_strength(self, strength)


func _set_death_burn_value(value: float) -> void:
	if _death_burn_material:
		_death_burn_material.set_shader_parameter("dissolve_value", value)


func _configure_feedback_materials() -> void:
	CardVisualCombatFeedback.configure_materials(self)


func _get_visual_radius_along(direction: Vector2, scale_value: float) -> float:
	var bounds := _get_visual_bounds()
	var min_point := bounds.position
	var max_point := bounds.end
	var center := card_size * 0.5
	var radius := 0.0
	var corners := [min_point, Vector2(max_point.x, min_point.y), max_point, Vector2(min_point.x, max_point.y)]
	for corner in corners:
		radius = maxf(radius, direction.dot((corner - center) * scale_value))
	return radius


func _apply_rarity(rarity: CardData.Rarity) -> void:
	CardVisualLayout.apply_rarity(self, rarity)


func _fit_description_text() -> void:
	CardVisualLayout.fit_description_text(self)


func _fit_title_text() -> void:
	CardVisualLayout.fit_title_text(self)


func _on_mouse_entered() -> void:
	_hovered = true
	hover_changed.emit(self, true)
	if _interaction_blocked:
		return
	if _dragging or _snapping:
		return
	_last_hover_z_index += 1
	_resting_z_index = _last_hover_z_index
	_stop_tweens()
	z_index = _resting_z_index

	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(card_surface, "scale", Vector2.ONE * hover_scale, hover_duration)
	_motion_tween.tween_property(card_surface, "position:y", -hover_lift, hover_duration)


func _on_mouse_exited() -> void:
	_hovered = false
	hover_changed.emit(self, false)
	if _interaction_blocked:
		return
	if _dragging or _snapping:
		return
	_stop_tweens()

	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion_tween.tween_property(card_surface, "scale", Vector2.ONE, release_duration)
	_motion_tween.tween_property(card_surface, "rotation_degrees", 0.0, release_duration)
	_motion_tween.tween_property(card_surface, "position:y", 0.0, release_duration)


func _start_drag() -> void:
	if _dragging:
		return
	_snapping = false
	_dragging = true
	if _current_slot:
		_current_slot.release(self)
		_current_slot = null
	else:
		for node in get_tree().get_nodes_in_group("card_slots"):
			var slot: CardSlot = node as CardSlot
			if slot:
				slot.release(self)
	_drag_offset = get_global_mouse_position() - global_position
	_drag_tilt_target = 0.0
	_stop_tweens()
	z_index = DRAG_Z_INDEX
	drag_started.emit(self)

	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(
		card_surface,
		"scale",
		Vector2.ONE * (hover_scale + drag_pickup_zoom_bonus),
		hover_duration
	)
	_motion_tween.tween_property(card_surface, "position:y", -hover_lift, hover_duration)

	_pickup_sway_active = true
	_sway_tween = create_tween()
	_sway_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway_tween.tween_property(card_surface, "rotation_degrees", -drag_pickup_sway, hover_duration * 0.25)
	_sway_tween.tween_property(card_surface, "rotation_degrees", drag_pickup_sway, hover_duration * 0.5)
	_sway_tween.tween_property(card_surface, "rotation_degrees", 0.0, hover_duration * 0.25)
	_sway_tween.finished.connect(_on_pickup_sway_finished)


func _stop_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	_effect_outline_locked = false
	_drag_tilt_target = 0.0
	_clear_merge_outline_target()
	_stop_tweens()
	var merge_target := _find_merge_target()
	if merge_target:
		merge_started.emit(self, merge_target)
		merge_target.merge_animator.play(self, merge_target)
		return
	var target_slot := _find_drop_slot()
	var snapped_to_slot := target_slot != null
	if snapped_to_slot:
		target_slot.occupy(self)
		_current_slot = target_slot
		slotted.emit(self)
	z_index = _resting_z_index

	if snapped_to_slot:
		_snapping = true
		_motion_tween = create_tween().set_parallel(true)
		_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_motion_tween.tween_property(card_surface, "scale", Vector2.ONE, snap_duration)
		_motion_tween.tween_property(card_surface, "rotation_degrees", 0.0, snap_duration)
		_motion_tween.tween_property(card_surface, "position:y", 0.0, snap_duration)
		_motion_tween.tween_property(self, "global_position", target_slot.get_snap_position(card_size), snap_duration)
		_motion_tween.finished.connect(_on_snap_finished)
		return
	if _is_over_sell_zone():
		sell_requested.emit(self)
		return
	invalid_drop_requested.emit(self)


func prepare_for_collection() -> void:
	_effect_outline_locked = false
	_clear_merge_outline_target()
	_stop_tweens()
	_hovered = false
	_dragging = false
	_snapping = true
	_interaction_blocked = true
	z_index = DRAG_Z_INDEX
	if _trait_tooltip:
		_trait_tooltip.hide()


func _find_drop_slot() -> CardSlot:
	for node in get_tree().get_nodes_in_group("card_slots"):
		var slot := node as CardSlot
		if slot and slot.can_accept(self):
			return slot
	return null


func _is_over_sell_zone() -> bool:
	var card_center: Vector2 = get_card_center()
	for node in get_tree().get_nodes_in_group("card_sell_zones"):
		var zone: Control = node as Control
		if zone and zone.visible and zone.get_global_rect().has_point(card_center):
			return true
	return false


func _is_over_valid_drop_destination() -> bool:
	return _find_drop_slot() != null or _is_over_sell_zone()


func _find_merge_target() -> CardVisual:
	var target: CardVisual = null
	var hover_point: Vector2 = get_global_mouse_position()
	for node in get_tree().get_nodes_in_group("card_visuals"):
		var candidate := node as CardVisual
		if not candidate or not can_merge_with(candidate):
			continue
		if candidate._interaction_blocked or candidate._dragging or candidate._snapping:
			continue
		if not candidate.is_visible_in_tree() or not candidate._contains_visual_point(hover_point):
			continue
		if not target or candidate.z_index > target.z_index:
			target = candidate
	return target


func _on_snap_finished() -> void:
	_snapping = false
	z_index = _resting_z_index


func _on_pickup_sway_finished() -> void:
	_pickup_sway_active = false


func _stop_tweens() -> void:
	_pickup_sway_active = false
	attack_returning = false
	if _motion_tween:
		_motion_tween.kill()
	if _sway_tween:
		_sway_tween.kill()
	if _flash_tween:
		_flash_tween.kill()
	if is_node_ready():
		visual_group.material = _hit_flash_material
		_set_hit_flash_strength(0.0)
