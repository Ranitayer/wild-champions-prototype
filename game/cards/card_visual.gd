class_name CardVisual
extends Control

const OUTLINE_WIDTH := 4
const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
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

@export_group("Data")
@export var card_data: CardData

@export_group("Card")
@export var card_size: Vector2 = Vector2(187.0, 262.0)

@export_group("Hover")
@export_range(1.0, 2.0, 0.05) var hover_scale: float = 1.3
@export_range(0.0, 100.0, 1.0) var hover_lift: float = 24.0
@export_range(0.01, 1.0, 0.01) var hover_duration: float = 0.22
@export_range(0.01, 1.0, 0.01) var release_duration: float = 0.12

@export_group("Drag")
@export var drag_enabled: bool = true
@export_range(1, 1000, 1) var drag_z_index: int = 100
@export_range(0.0, 0.5, 0.05) var drag_pickup_zoom_bonus: float = 0.1
@export_range(0.0, 15.0, 0.5) var drag_pickup_sway: float = 3.0
@export_range(0.0, 0.5, 0.05) var drag_release_bob: float = 0.1
@export_range(0.0, 20.0, 0.5) var drag_max_sway: float = 8.0
@export_range(0.0, 2.0, 0.05) var drag_sway_sensitivity: float = 0.35
@export_range(1.0, 40.0, 1.0) var drag_sway_response: float = 18.0
@export_range(1.0, 100.0, 1.0) var drag_sway_return_speed: float = 45.0

@export_group("Title")
@export var title_box_size: Vector2 = Vector2(207.0, 50.0)
@export_range(-100.0, 100.0, 1.0) var title_box_offset_y: float = 10.0
@export_range(0, 15, 1) var title_box_corner_radius: int = 6
@export_range(8, 48, 1) var title_font_size: int = 20
@export_range(0.0, 40.0, 1.0) var title_side_margin: float = 10.0

@export_group("Description")
@export_range(0.0, 60.0, 1.0) var description_side_margin: float = 12.0
@export_range(0.0, 60.0, 1.0) var description_top_gap: float = 10.0
@export_range(0.0, 100.0, 1.0) var description_bottom_margin: float = 28.0
@export_range(8, 36, 1) var description_min_font_size: int = 10
@export_range(8, 36, 1) var description_max_font_size: int = 18

@export_group("Bottom Stats")
@export_range(16.0, 100.0, 1.0) var bottom_stat_size: float = 55.0
@export_range(-100.0, 100.0, 1.0) var bottom_stat_horizontal_inset: float = -10.0
@export_range(-100.0, 100.0, 1.0) var bottom_stat_offset_y: float = 15.0
@export var attack_color: Color = Color("4f8fba")
@export var health_color: Color = Color("a53030")

@export_group("Cooldown Stat")
@export_range(16.0, 100.0, 1.0) var cooldown_stat_size: float = 55.0
@export var cooldown_stat_position: Vector2 = Vector2(-12.0, -12.0)
@export var cooldown_stat_color: Color = DARK_COLOR

@onready var card_surface: Panel = %CardSurface
@onready var rarity_top: Panel = %RarityTop
@onready var rarity_bottom: Panel = %RarityBottom
@onready var title_box: Panel = %TitleBox
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var attack_stat: StatCircle = %AttackStat
@onready var health_stat: StatCircle = %HealthStat
@onready var cooldown_stat: StatCircle = %CooldownStat

var _motion_tween: Tween
var _sway_tween: Tween
var _hovered := false
var _dragging := false
var _drag_offset := Vector2.ZERO
var _drag_tilt_target := 0.0
var _pickup_sway_active := false


func _ready() -> void:
	_configure_layout()
	_apply_data()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(delta: float) -> void:
	if not _dragging or _pickup_sway_active:
		return
	var response := 1.0 - exp(-drag_sway_response * delta)
	card_surface.rotation_degrees = lerpf(card_surface.rotation_degrees, _drag_tilt_target, response)
	_drag_tilt_target = move_toward(_drag_tilt_target, 0.0, drag_sway_return_speed * delta)


func _gui_input(event: InputEvent) -> void:
	if not drag_enabled:
		return
	var mouse_button := event as InputEventMouseButton
	if not mouse_button or mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_button.pressed:
		_start_drag()
	elif _dragging:
		_stop_drag()
	accept_event()


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

	var title_style := title_box.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	title_style.set_corner_radius_all(title_box_corner_radius)
	title_box.add_theme_stylebox_override("panel", title_style)

	var description_top := title_box.position.y + title_box.size.y + description_top_gap
	var description_bottom := card_size.y - description_bottom_margin
	description_label.position = Vector2(description_side_margin, description_top)
	description_label.size = Vector2(
		maxf(0.0, card_size.x - description_side_margin * 2.0),
		maxf(0.0, description_bottom - description_top)
	)

	var bottom_dimensions := Vector2.ONE * bottom_stat_size
	var bottom_y := card_size.y - bottom_stat_size + bottom_stat_offset_y
	attack_stat.size = bottom_dimensions
	health_stat.size = bottom_dimensions
	attack_stat.position = Vector2(bottom_stat_horizontal_inset, bottom_y)
	health_stat.position = Vector2(card_size.x - bottom_stat_size - bottom_stat_horizontal_inset, bottom_y)
	attack_stat.fill_color = attack_color
	health_stat.fill_color = health_color

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


func _apply_data() -> void:
	var data := card_data if card_data else CardData.new()
	title_label.text = data.title
	description_label.text = data.description
	attack_stat.value = data.attack
	health_stat.value = data.health
	cooldown_stat.value = data.cooldown
	_apply_rarity(data.rarity)
	_fit_description_text()


func _apply_rarity(rarity: CardData.Rarity) -> void:
	var index := clampi(rarity, 0, RARITY_TOP_COLORS.size() - 1)
	var top_style := rarity_top.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var bottom_style := rarity_bottom.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	top_style.bg_color = RARITY_TOP_COLORS[index]
	bottom_style.bg_color = RARITY_BOTTOM_COLORS[index]
	rarity_top.add_theme_stylebox_override("panel", top_style)
	rarity_bottom.add_theme_stylebox_override("panel", bottom_style)


func _fit_description_text() -> void:
	var font := description_label.get_theme_font("font")
	var smallest := mini(description_min_font_size, description_max_font_size)
	var largest := maxi(description_min_font_size, description_max_font_size)
	for font_size in range(largest, smallest - 1, -1):
		var text_size := font.get_multiline_string_size(
			description_label.text,
			HORIZONTAL_ALIGNMENT_CENTER,
			description_label.size.x,
			font_size
		)
		if text_size.y <= description_label.size.y:
			description_label.add_theme_font_size_override("font_size", font_size)
			return
	description_label.add_theme_font_size_override("font_size", smallest)


func _on_mouse_entered() -> void:
	_hovered = true
	if _dragging:
		return
	_stop_tweens()
	z_index = 1

	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(card_surface, "scale", Vector2.ONE * hover_scale, hover_duration)
	_motion_tween.tween_property(card_surface, "position:y", -hover_lift, hover_duration)


func _on_mouse_exited() -> void:
	_hovered = false
	if _dragging:
		return
	_stop_tweens()
	z_index = 0

	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion_tween.tween_property(card_surface, "scale", Vector2.ONE, release_duration)
	_motion_tween.tween_property(card_surface, "rotation_degrees", 0.0, release_duration)
	_motion_tween.tween_property(card_surface, "position:y", 0.0, release_duration)


func _start_drag() -> void:
	if _dragging:
		return
	_dragging = true
	_drag_offset = get_global_mouse_position() - global_position
	_drag_tilt_target = 0.0
	_stop_tweens()
	z_index = drag_z_index

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
	z_index = 1 if _hovered else 0

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


func _on_pickup_sway_finished() -> void:
	_pickup_sway_active = false


func _stop_tweens() -> void:
	_pickup_sway_active = false
	if _motion_tween:
		_motion_tween.kill()
	if _sway_tween:
		_sway_tween.kill()
