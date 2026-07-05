class_name CardVisual
extends Control

signal drag_started(card: CardVisual)
signal stat_changed(card: CardVisual, stat_type: CardStat.Type, delta: int)
signal tier_changed(card: CardVisual, tier: int)

const OUTLINE_WIDTH := 4
const DARK_COLOR := Color("151d28")
const ORANGE_COLOR := Color("ffa500")
const TRAIT_COLOR_HEX := "de9e41"
const TRAIT_COLOR := Color("de9e41")
const DRAG_Z_INDEX := 4096
const COMBAT_Z_INDEX := 2048
const TOOLTIP_CANVAS_LAYER := 102
const CARD_TRAIT_TOOLTIP := preload("res://game/ui/card_trait_tooltip/card_trait_tooltip.gd")
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

@export var card_data: CardData

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

var hit_shake_distance := 6.0
var hit_shake_count := 3
var hit_flash_duration := 0.08
var hit_orange_duration := 0.10
var survival_sway_count := 4
var dodge_rotation_degrees := 6.0
var card_size := Vector2(200.0, 275.0)
var art_margin := 8.0
var hover_scale := 1.4
var hover_lift := 24.0
var hover_duration := 0.22
var release_duration := 0.12
var drag_pickup_zoom_bonus := 0.1
var drag_pickup_sway := 3.0
var drag_release_bob := 0.1
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
var title_side_margin := 10.0
var description_side_margin := 12.0
var description_top_gap := 10.0
var description_bottom_margin := 28.0
var description_stat_gap := 8.0
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
var _hovered := false
var _dragging := false
var _snapping := false
var _drag_offset := Vector2.ZERO
var _drag_tilt_target := 0.0
var _pickup_sway_active := false
var _current_slot: CardSlot
var _interaction_blocked := false
var _tooltip_hover_while_blocked := false
var _resting_z_index := 0
var _attack_start_position := Vector2.ZERO
var _attack_start_z_index := 0
var _attack_returning := false
var _suppress_stat_changes := false
var _description_plain_text := ""
var _trait_tooltip
var _trait_tooltip_layer: CanvasLayer
var _base_tooltip_sections: Array[Dictionary] = []
var _card_tier := 1

static var _last_hover_z_index := 0


func _ready() -> void:
	add_to_group("card_visuals")
	_configure_feedback_materials()
	_configure_layout()
	_apply_data()
	_configure_trait_tooltip()
	card_surface.gui_input.connect(_gui_input)
	title_box.gui_input.connect(_gui_input)
	attack_stat.gui_input.connect(_gui_input)
	temporary_attack_stat.gui_input.connect(_gui_input)
	health_stat.gui_input.connect(_gui_input)
	poison_stat.gui_input.connect(_gui_input)
	cooldown_stat.gui_input.connect(_gui_input)


func _process(delta: float) -> void:
	_update_hover_state()
	_update_trait_tooltip_visibility()
	_update_trait_tooltip_position()
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
	if _try_start_drag(event):
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if _try_start_drag(event):
		accept_event()


func _try_start_drag(event: InputEvent) -> bool:
	if _interaction_blocked or _dragging:
		return false
	var mouse_button := event as InputEventMouseButton
	if not mouse_button or mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return false
	if not _is_top_card_at(get_global_mouse_position()):
		return false
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
	return false


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion:
		global_position = get_global_mouse_position() - _drag_offset
		_drag_tilt_target = clampf(
			mouse_motion.relative.x * drag_sway_sensitivity,
			-drag_max_sway,
			drag_max_sway
		)
	var mouse_button := event as InputEventMouseButton
	if mouse_button and mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
		_stop_drag()


func _configure_layout() -> void:
	custom_minimum_size = card_size
	size = card_size
	card_surface.size = card_size
	card_surface.pivot_offset = card_size * 0.5

	title_box.size = title_box_size
	title_box.position = (card_size - title_box_size) * 0.5 + Vector2.DOWN * title_box_offset_y
	title_label.position = Vector2(title_side_margin, 0.0)
	title_label.size = Vector2(title_box_size.x - title_side_margin * 2.0, title_box_size.y)
	title_label.add_theme_font_size_override("font_size", title_font_size)
	_configure_rarity_panels()
	_configure_art()

	var title_style := title_box.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	title_style.set_corner_radius_all(title_box_corner_radius)
	title_box.add_theme_stylebox_override("panel", title_style)

	var bottom_y := card_size.y - bottom_stat_size + bottom_stat_offset_y
	var description_top := title_box.position.y + title_box.size.y + description_top_gap
	var description_bottom := minf(
		card_size.y - description_bottom_margin,
		bottom_y - description_stat_gap
	)
	description_label.position = Vector2(description_side_margin, description_top)
	description_label.size = Vector2(
		maxf(0.0, card_size.x - description_side_margin * 2.0),
		maxf(0.0, description_bottom - description_top)
	)

	var bottom_dimensions := Vector2.ONE * bottom_stat_size
	attack_stat.size = bottom_dimensions
	health_stat.size = bottom_dimensions
	attack_stat.position = Vector2(bottom_stat_horizontal_inset, bottom_y)
	health_stat.position = Vector2(card_size.x - bottom_stat_size - bottom_stat_horizontal_inset, bottom_y)
	attack_stat.fill_color = attack_color
	health_stat.fill_color = health_color
	var temporary_attack_size := bottom_stat_size * temporary_attack_stat_scale
	temporary_attack_stat.size = Vector2.ONE * temporary_attack_size
	temporary_attack_stat.position = Vector2(
		attack_stat.position.x + bottom_stat_size + temporary_attack_stat_margin,
		attack_stat.position.y + (bottom_stat_size - temporary_attack_size) * 0.5
	)
	temporary_attack_stat.fill_color = CardStat.TEMPORARY_ATTACK_COLOR
	var poison_size := bottom_stat_size * poison_stat_scale
	poison_stat.size = Vector2.ONE * poison_size
	poison_stat.position = Vector2(
		health_stat.position.x - poison_size - poison_stat_margin,
		health_stat.position.y + (bottom_stat_size - poison_size) * 0.5
	)
	poison_stat.fill_color = CardStat.POISON_COLOR

	cooldown_stat.size = Vector2.ONE * cooldown_stat_size
	cooldown_stat.position = cooldown_stat_position
	cooldown_stat.fill_color = cooldown_stat_color


func _configure_rarity_panels() -> void:
	var split_y := title_box.position.y + title_box.size.y * 0.5
	var inner_width := maxf(0.0, card_size.x - OUTLINE_WIDTH * 2.0)
	rarity_top.position = Vector2(OUTLINE_WIDTH, OUTLINE_WIDTH)
	rarity_top.size = Vector2(inner_width, maxf(0.0, split_y - OUTLINE_WIDTH))
	rarity_bottom.position = Vector2(OUTLINE_WIDTH, split_y)
	rarity_bottom.size = Vector2(inner_width, maxf(0.0, card_size.y - split_y - OUTLINE_WIDTH))


func _configure_art() -> void:
	var data := card_data if card_data else CardData.new()
	var base_size := Vector2(
		card_size.x - art_margin * 2.0,
		title_box.position.y - art_margin * 2.0
	)
	art_texture.position = Vector2.ONE * art_margin + data.art_offset
	art_texture.size = base_size
	art_texture.pivot_offset = art_texture.size * 0.5
	art_texture.scale = Vector2.ONE * data.art_scale


func _apply_data() -> void:
	var data := card_data if card_data else CardData.new()
	title_label.text = data.title
	_apply_description(data)
	art_texture.texture = data.art
	_card_tier = clampi(data.tier, 1, CardData.MAX_TIER)
	tier_indicator.tier = _card_tier
	attack_stat.value = data.attack
	health_stat.value = data.health
	cooldown_stat.value = data.cooldown
	_apply_rarity(data.rarity)
	_fit_description_text()


func _apply_description(data: CardData) -> void:
	var trait_lines: Array[String] = []
	for trait_resource in data.traits:
		var trait_definition := trait_resource as CardTrait
		if trait_definition:
			trait_lines.append(trait_definition.get_display_text())
	var trait_text := "\n".join(trait_lines)
	_description_plain_text = data.description
	if not trait_text.is_empty():
		_description_plain_text += ("\n" if not _description_plain_text.is_empty() else "") + trait_text

	var parts: Array[String] = []
	if not data.description.is_empty():
		parts.append(data.description)
	if not trait_text.is_empty():
		parts.append("[color=#%s]%s[/color]" % [TRAIT_COLOR_HEX, trait_text])
	description_label.text = "[center]%s[/center]" % "\n".join(parts)


func _configure_trait_tooltip() -> void:
	if not card_data:
		return
	_base_tooltip_sections.clear()
	for trait_resource in card_data.traits:
		var trait_definition := trait_resource as CardTrait
		if trait_definition:
			_base_tooltip_sections.append({
				"title": trait_definition.get_display_text(),
				"description": trait_definition.get_tooltip_description(),
				"color": TRAIT_COLOR,
			})
	_refresh_trait_tooltip()


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
	var next_tier := clampi(value, 1, CardData.MAX_TIER)
	if next_tier == _card_tier:
		return
	_card_tier = next_tier
	tier_indicator.tier = _card_tier
	tier_changed.emit(self, _card_tier)


func can_merge_with(other: CardVisual) -> bool:
	if not is_instance_valid(other) or other == self:
		return false
	if _card_tier != other._card_tier or _card_tier >= CardData.MAX_TIER:
		return false
	if not card_data or not other.card_data:
		return false
	if card_data == other.card_data:
		return true
	return not card_data.resource_path.is_empty() and card_data.resource_path == other.card_data.resource_path


func prepare_for_merge() -> void:
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
	var normalized_value := maxi(0, value)
	var delta := normalized_value - stat.value
	stat.value = normalized_value
	if delta != 0 and show_popup and not _suppress_stat_changes:
		stat_changed.emit(self, stat_type, delta)


func reset_combat_visuals() -> void:
	_stop_tweens()
	_suppress_stat_changes = true
	_hovered = false
	_dragging = false
	_snapping = false
	self_modulate = Color.WHITE
	visual_group.material = _hit_flash_material
	_set_hit_flash_strength(0.0)
	card_surface.position = Vector2.ZERO
	card_surface.scale = Vector2.ONE
	card_surface.rotation_degrees = 0.0
	set_attack_value(card_data.attack if card_data else 0)
	set_temporary_attack_value(0, false)
	set_health_value(card_data.health if card_data else 0)
	set_cooldown_value(maxi(1, card_data.cooldown) if card_data else 1)
	set_poison_value(0, false)
	_suppress_stat_changes = false


func play_attack_to_impact(target_center: Vector2) -> void:
	_stop_tweens()
	_attack_start_position = global_position
	_attack_start_z_index = z_index
	var direction := (target_center - get_card_center()).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	var anticipation_position := _attack_start_position - direction * attack_anticipation_distance
	var charge_distance := (
		_get_visual_radius_along(direction, attack_scale)
		+ _get_visual_radius_along(-direction, 1.0)
		+ attack_impact_margin
	)
	var charge_position := target_center - direction * charge_distance - card_size * 0.5
	var aim_rotation := clampf(direction.x * attack_aim_rotation_degrees, -attack_aim_rotation_degrees, attack_aim_rotation_degrees)

	z_index = COMBAT_Z_INDEX
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "global_position", anticipation_position, attack_anticipation_duration)
	_motion_tween.parallel().tween_property(card_surface, "scale", Vector2.ONE * attack_scale, attack_anticipation_duration)
	_motion_tween.parallel().tween_property(card_surface, "rotation_degrees", aim_rotation, attack_anticipation_duration)
	_motion_tween.tween_property(self, "global_position", charge_position, attack_charge_duration).set_trans(Tween.TRANS_BACK)
	await _motion_tween.finished


func start_attack_return() -> void:
	_attack_returning = true
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "global_position", _attack_start_position, attack_return_duration)
	_motion_tween.parallel().tween_property(card_surface, "scale", Vector2.ONE, attack_return_duration)
	_motion_tween.parallel().tween_property(card_surface, "rotation_degrees", 0.0, attack_return_duration)
	_motion_tween.finished.connect(_on_attack_return_finished)


func is_attack_returning() -> bool:
	return _attack_returning


func _on_attack_return_finished() -> void:
	_attack_returning = false
	z_index = _attack_start_z_index


func play_hit_animation(attacker_center: Vector2) -> void:
	_stop_tweens()
	visual_group.material = _hit_flash_material
	_flash_hit()
	var start_position := card_surface.position
	var knockback_direction := (get_card_center() - attacker_center).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.DOWN
	var shake_direction := Vector2(-knockback_direction.y, knockback_direction.x)
	var knockback_position := start_position + knockback_direction * hit_knockback_distance

	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(card_surface, "position", knockback_position, hit_duration * 0.35)
	for shake_index in range(hit_shake_count):
		var shake_sign := -1.0 if shake_index % 2 == 0 else 1.0
		var shake_position := knockback_position + shake_direction * hit_shake_distance * shake_sign
		_motion_tween.tween_property(card_surface, "position", shake_position, hit_duration / maxf(1.0, float(hit_shake_count)))
		_motion_tween.parallel().tween_property(card_surface, "rotation_degrees", hit_rotation_shake_degrees * shake_sign, hit_duration / maxf(1.0, float(hit_shake_count)))
	_motion_tween.tween_property(card_surface, "position", start_position, hit_duration * 0.35)
	_motion_tween.parallel().tween_property(card_surface, "rotation_degrees", 0.0, hit_duration * 0.35)
	await _motion_tween.finished


func play_death_animation() -> void:
	_stop_tweens()
	hide()


func play_survival_animation() -> void:
	_stop_tweens()
	var step_duration := survival_sway_duration / float(survival_sway_count + 1)
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for sway_index in range(survival_sway_count):
		var sway_sign := -1.0 if sway_index % 2 == 0 else 1.0
		_motion_tween.tween_property(
			card_surface,
			"rotation_degrees",
			survival_rotation_degrees * sway_sign,
			step_duration
		)
		if sway_index == 0:
			_motion_tween.parallel().tween_property(
				card_surface,
				"scale",
				Vector2.ONE * survival_pop_scale,
				step_duration
			)
	_motion_tween.tween_property(card_surface, "rotation_degrees", 0.0, step_duration)
	_motion_tween.parallel().tween_property(card_surface, "scale", Vector2.ONE, step_duration)
	await _motion_tween.finished


func play_dodge_animation(direction: float) -> void:
	_stop_tweens()
	var dodge_sign := signf(direction)
	if dodge_sign == 0.0:
		dodge_sign = 1.0
	var start_position := card_surface.position
	var half_duration := dodge_duration * 0.5
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(
		card_surface,
		"position:x",
		start_position.x + dodge_distance * dodge_sign,
		half_duration
	)
	_motion_tween.parallel().tween_property(
		card_surface,
		"rotation_degrees",
		dodge_rotation_degrees * dodge_sign,
		half_duration
	)
	_motion_tween.tween_property(card_surface, "position:x", start_position.x, half_duration)
	_motion_tween.parallel().tween_property(card_surface, "rotation_degrees", 0.0, half_duration)
	await _motion_tween.finished


func _flash_hit() -> void:
	if _flash_tween:
		_flash_tween.kill()
	if _buff_tween:
		_buff_tween.kill()
	_set_hit_flash_color(Color.WHITE)
	_set_hit_flash_strength(1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(hit_flash_duration)
	_flash_tween.tween_callback(_set_hit_flash_color.bind(ORANGE_COLOR))
	_flash_tween.tween_interval(hit_orange_duration)
	_flash_tween.tween_method(_set_hit_flash_strength, 1.0, 0.0, hit_flash_duration)


func _set_hit_flash_color(color: Color) -> void:
	visual_group.material = _hit_flash_material
	var flash_material := visual_group.material as ShaderMaterial
	if flash_material:
		flash_material.set_shader_parameter("flash_color", color)


func _set_hit_flash_strength(strength: float) -> void:
	visual_group.material = _hit_flash_material
	var flash_material := visual_group.material as ShaderMaterial
	if flash_material:
		flash_material.set_shader_parameter("flash_strength", strength)


func _configure_feedback_materials() -> void:
	_hit_flash_material = visual_group.material as ShaderMaterial
	if _hit_flash_material:
		_hit_flash_material = _hit_flash_material.duplicate() as ShaderMaterial
		visual_group.material = _hit_flash_material


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
	var index := clampi(rarity, 0, RARITY_TOP_COLORS.size() - 1)
	var top_style := rarity_top.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var bottom_style := rarity_bottom.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	top_style.bg_color = RARITY_TOP_COLORS[index]
	bottom_style.bg_color = RARITY_BOTTOM_COLORS[index]
	rarity_top.add_theme_stylebox_override("panel", top_style)
	rarity_bottom.add_theme_stylebox_override("panel", bottom_style)


func _fit_description_text() -> void:
	var font := description_label.get_theme_font("normal_font")
	var smallest := mini(description_min_font_size, description_max_font_size)
	var largest := maxi(description_min_font_size, description_max_font_size)
	for font_size in range(largest, smallest - 1, -1):
		var text_size := font.get_multiline_string_size(
			_description_plain_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			description_label.size.x,
			font_size
		)
		if text_size.y <= description_label.size.y:
			description_label.add_theme_font_size_override("normal_font_size", font_size)
			return
	description_label.add_theme_font_size_override("normal_font_size", smallest)


func _on_mouse_entered() -> void:
	_hovered = true
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
	_drag_tilt_target = 0.0
	_stop_tweens()
	var merge_target := _find_merge_target()
	if merge_target:
		merge_target.merge_animator.play(self, merge_target)
		return
	var target_slot := _find_drop_slot()
	var snapped_to_slot := target_slot != null
	if snapped_to_slot:
		target_slot.occupy(self)
		_current_slot = target_slot
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

	var target_scale_value := hover_scale if _hovered else 1.0
	var bob_scale := Vector2.ONE * maxf(0.1, target_scale_value - drag_release_bob)
	var target_scale := Vector2.ONE * target_scale_value
	var target_y := -hover_lift if _hovered else 0.0
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(card_surface, "scale", bob_scale, release_duration)
	_motion_tween.tween_property(card_surface, "rotation_degrees", 0.0, release_duration)
	_motion_tween.tween_property(card_surface, "position:y", target_y, release_duration)
	_motion_tween.chain().tween_property(card_surface, "scale", target_scale, release_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _find_drop_slot() -> CardSlot:
	for node in get_tree().get_nodes_in_group("card_slots"):
		var slot := node as CardSlot
		if slot and slot.can_accept(self):
			return slot
	return null


func _find_merge_target() -> CardVisual:
	var target: CardVisual = null
	var card_center := get_card_center()
	for node in get_tree().get_nodes_in_group("card_visuals"):
		var candidate := node as CardVisual
		if not candidate or not can_merge_with(candidate):
			continue
		if candidate._interaction_blocked or candidate._dragging or candidate._snapping:
			continue
		if not candidate.is_visible_in_tree() or not candidate.get_global_rect().has_point(card_center):
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
	_attack_returning = false
	if _motion_tween:
		_motion_tween.kill()
	if _sway_tween:
		_sway_tween.kill()
	if _flash_tween:
		_flash_tween.kill()
	if is_node_ready():
		visual_group.material = _hit_flash_material
		_set_hit_flash_strength(0.0)
