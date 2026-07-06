class_name BoosterPack
extends TextureRect

signal open_requested(pack: BoosterPack)
signal hover_changed(pack: BoosterPack, hovered: bool)

const SHINE_SHADER: Shader = preload("res://game/effects/shaders/sharp_shine.gdshader")
const DEFAULT_PACK_DATA: Resource = preload("res://content/booster_packs/basic_booster.tres")
const DARK_COLOR := Color("151d28")
const PRICE_COLOR := Color("de9e41")

@export var pack_data: Resource = DEFAULT_PACK_DATA

@export_group("Slide")
@export var center_offset_x := 0.0
@export_range(0.1, 2.0, 0.05) var slide_duration := 0.55
@export var start_horizontal_offset := 120.0
@export_range(-45.0, 45.0, 1.0) var start_rotation_degrees := 14.0
@export_range(-15.0, 15.0, 0.5) var landed_rotation_degrees := -4.0

@export_group("Close")
@export_range(0.02, 0.3, 0.01) var close_anticipation_duration := 0.10
@export_range(0.05, 0.5, 0.01) var close_zoom_duration := 0.22
@export_range(1.0, 1.3, 0.01) var close_anticipation_scale := 1.04
@export_range(0.0, 0.5, 0.01) var close_end_scale := 0.05

@export_group("Shine")
@export_range(0.5, 10.0, 0.1) var shine_interval := 3.0
@export_range(0.05, 1.0, 0.01) var shine_duration := 0.36
@export_range(0.01, 0.5, 0.01) var shine_width := 0.11

@export_group("Hover")
@export_range(1.0, 1.4, 0.01) var hover_scale := 1.08
@export_range(0.05, 0.4, 0.01) var hover_duration := 0.14

@export_group("Open Pack")
@export_range(0.2, 2.0, 0.05) var open_duration := 1.0
@export_range(0.0, 16.0, 0.5) var open_shake_pixels := 5.0
@export_range(0.75, 1.0, 0.01) var open_end_scale := 0.95
@export_range(0.5, 8.0, 0.1) var open_ray_speed := 4.0
@export_range(0.0, 1.0, 0.05) var open_dim_alpha := 0.65

var _shine_overlay: ColorRect
var _white_overlay: ColorRect
var _shine_version := 0
var _motion_tween: Tween
var _hover_tween: Tween
var _open_tween: Tween
var _hovered := false
var _opening := false
var _sliding := false
var _payment_pending := false
var _closing := false

@onready var ray_burst: RayBurstEffect = $RayBurstEffect
@onready var floating_effect: FloatingEffect = $FloatingEffect
@onready var price_stat: StatCircle = $PriceStat
@onready var pack_background: Panel = $PackBackground
@onready var inner_outline: Panel = $InnerOutline
@onready var pack_letter: Label = $PackLetter


func _enter_tree() -> void:
	add_to_group("booster_packs")
	add_to_group("shop_purchasables")


func _ready() -> void:
	texture = null
	pivot_offset = _get_shine_bounds().get_center()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_shine_overlay()
	_create_white_overlay()
	_apply_pack_data()
	hide()


func _process(_delta: float) -> void:
	var hovering: bool = visible and not _opening and not _payment_pending and not _closing and _contains_pointer()
	if hovering == _hovered:
		return
	if hovering:
		_on_mouse_entered()
	else:
		_on_mouse_exited()


func _input(event: InputEvent) -> void:
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_button or mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return
	if _opening or _payment_pending or _closing or not visible or not _contains_pointer():
		return
	get_viewport().set_input_as_handled()
	open_requested.emit(self)


func play_shop_open() -> void:
	_shine_version += 1
	_hovered = false
	_opening = false
	_payment_pending = false
	_closing = false
	ray_burst.stop()
	ray_burst.reset_runtime_settings()
	floating_effect.stop()
	_apply_pack_data()
	await _slide_in()
	if _hovered:
		_animate_hover(true)
	else:
		floating_effect.start(self)
	_start_shine_loop(_shine_version)


func restore_after_reward() -> void:
	play_shop_open()


func play_shop_close() -> void:
	if not visible:
		return
	_closing = true
	_shine_version += 1
	_hovered = false
	hover_changed.emit(self, false)
	_opening = false
	ray_burst.stop()
	ray_burst.reset_runtime_settings()
	floating_effect.stop()
	_kill_open_tween()
	_kill_hover_tween()
	_kill_motion_tween()
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * close_anticipation_scale, close_anticipation_duration)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * close_end_scale, close_zoom_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion_tween.parallel().tween_property(self, "modulate:a", 0.0, close_zoom_duration)
	await _motion_tween.finished
	hide()
	_closing = false
	scale = Vector2.ONE
	modulate.a = 1.0


func _slide_in() -> void:
	_sliding = true
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var target_position: Vector2 = Vector2(
		viewport_rect.position.x + viewport_rect.size.x * 0.5 - pivot_offset.x + center_offset_x,
		viewport_rect.position.y + viewport_rect.size.y * 0.5 - size.y
	)
	global_position = Vector2(
		target_position.x + start_horizontal_offset,
		viewport_rect.position.y - size.y
	)
	rotation_degrees = start_rotation_degrees
	scale = Vector2.ONE
	modulate.a = 1.0
	show()

	_kill_motion_tween()
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "global_position", target_position, slide_duration)
	_motion_tween.tween_property(self, "rotation_degrees", landed_rotation_degrees, slide_duration)
	await _motion_tween.finished
	_sliding = false


func _on_mouse_entered() -> void:
	if not visible or _opening:
		return
	_hovered = true
	hover_changed.emit(self, true)
	floating_effect.stop()
	ray_burst.start()
	_animate_hover(true)


func _on_mouse_exited() -> void:
	if not visible or _opening:
		return
	_hovered = false
	hover_changed.emit(self, false)
	ray_burst.stop()
	_animate_hover(false)
	await get_tree().create_timer(hover_duration).timeout
	if visible and not _hovered and not _sliding:
		floating_effect.start(self)


func _animate_hover(hovering: bool) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(
		self,
		"scale",
		Vector2.ONE * hover_scale if hovering else Vector2.ONE,
		hover_duration
	)
	if not _sliding:
		_hover_tween.tween_property(
			self,
			"rotation_degrees",
			0.0 if hovering else landed_rotation_degrees,
			hover_duration
		)


func _contains_pointer() -> bool:
	var pointer: Vector2 = get_global_mouse_position()
	return get_global_rect().has_point(pointer) or price_stat.get_global_rect().has_point(pointer)


func set_payment_pending(pending: bool) -> void:
	_payment_pending = pending
	if pending:
		_hovered = false
		hover_changed.emit(self, false)
		floating_effect.stop()
		ray_burst.stop()
		_kill_hover_tween()
		scale = Vector2.ONE
		rotation_degrees = landed_rotation_degrees
	elif visible:
		floating_effect.start(self)


func _kill_motion_tween() -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()


func _kill_open_tween() -> void:
	if _open_tween and _open_tween.is_valid():
		_open_tween.kill()


func _kill_hover_tween() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()


func play_open_pack(dim_overlay: ColorRect = null) -> void:
	if _opening:
		return
	_opening = true
	_shine_version += 1
	_hovered = false
	hover_changed.emit(self, false)
	floating_effect.stop()
	ray_burst.start()
	_kill_hover_tween()
	_kill_motion_tween()
	_kill_open_tween()
	var start_center: Vector2 = get_global_transform() * pivot_offset
	rotation_degrees = 0.0
	scale = Vector2.ONE
	global_position = start_center - pivot_offset
	_white_overlay.modulate.a = 0.0
	_white_overlay.show()
	_open_tween = create_tween().set_parallel(true)
	_open_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_open_tween.tween_method(_set_open_shake.bind(start_center), 0.0, 1.0, open_duration)
	_open_tween.tween_property(self, "scale", Vector2.ONE * open_end_scale, open_duration)
	_open_tween.tween_property(_white_overlay, "modulate:a", 1.0, open_duration)
	_open_tween.tween_method(_set_open_rays, 0.0, 1.0, open_duration)
	if dim_overlay:
		_open_tween.tween_property(dim_overlay, "color:a", open_dim_alpha, open_duration)
	await _open_tween.finished
	global_position = start_center - pivot_offset
	hide()
	_white_overlay.hide()
	_white_overlay.modulate.a = 0.0
	modulate.a = 1.0
	scale = Vector2.ONE
	ray_burst.stop()
	ray_burst.reset_runtime_settings()
	_opening = false


func _set_open_shake(value: float, start_center: Vector2) -> void:
	var strength: float = value * open_shake_pixels
	global_position = start_center - pivot_offset + Vector2(
		sin(value * TAU * 18.0) * strength,
		cos(value * TAU * 23.0) * strength
	)


func _set_open_rays(value: float) -> void:
	var ray_alpha: float = lerpf(0.55, 1.0, value)
	var ray_speed: float = lerpf(ray_burst.rotation_speed, open_ray_speed, value)
	ray_burst.set_runtime_settings(Color(1.0, 1.0, 1.0, ray_alpha), ray_speed)


func _start_shine_loop(version: int) -> void:
	while version == _shine_version and visible:
		await get_tree().create_timer(shine_interval).timeout
		if version != _shine_version or not visible:
			return
		await _play_shine()


func _play_shine() -> void:
	var shine_material: ShaderMaterial = _shine_overlay.material as ShaderMaterial
	shine_material.set_shader_parameter("shine_position", 0.0)
	var tween: Tween = create_tween()
	tween.tween_method(_set_shine_position, 0.0, 1.0, shine_duration)
	await tween.finished


func _set_shine_position(value: float) -> void:
	var shine_material: ShaderMaterial = _shine_overlay.material as ShaderMaterial
	shine_material.set_shader_parameter("shine_position", value)


func _create_shine_overlay() -> void:
	var shine_bounds: Rect2 = _get_shine_bounds()
	_shine_overlay = ColorRect.new()
	_shine_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shine_overlay.color = Color.WHITE
	_shine_overlay.position = shine_bounds.position
	_shine_overlay.size = shine_bounds.size
	add_child(_shine_overlay)
	_shine_overlay.material = _create_shine_material(shine_bounds)


func _create_white_overlay() -> void:
	var shine_bounds: Rect2 = _get_shine_bounds()
	_white_overlay = ColorRect.new()
	_white_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_white_overlay.color = Color.WHITE
	_white_overlay.position = shine_bounds.position
	_white_overlay.size = shine_bounds.size
	_white_overlay.modulate.a = 0.0
	add_child(_white_overlay)
	var white_material: ShaderMaterial = _create_shine_material(shine_bounds)
	white_material.set_shader_parameter("shine_width", 2.0)
	white_material.set_shader_parameter("shine_position", 0.5)
	_white_overlay.material = white_material
	_white_overlay.hide()


func _create_shine_material(shine_bounds: Rect2) -> ShaderMaterial:
	var shine_material: ShaderMaterial = ShaderMaterial.new()
	shine_material.shader = SHINE_SHADER
	shine_material.set_shader_parameter("overlay_size", shine_bounds.size)
	shine_material.set_shader_parameter("card_rect", _rect_to_vector4(Rect2(-shine_bounds.position, size)))
	shine_material.set_shader_parameter("card_radius", 8.0)
	shine_material.set_shader_parameter("title_rect", Vector4(-10.0, -10.0, 0.0, 0.0))
	shine_material.set_shader_parameter("title_radius", 0.0)
	shine_material.set_shader_parameter("attack_circle", Vector3(0.0, 0.0, -1.0))
	shine_material.set_shader_parameter("temporary_attack_circle", Vector3(0.0, 0.0, -1.0))
	shine_material.set_shader_parameter("health_circle", Vector3(0.0, 0.0, -1.0))
	shine_material.set_shader_parameter("poison_circle", Vector3(0.0, 0.0, -1.0))
	shine_material.set_shader_parameter("cooldown_circle", _get_shine_circle(price_stat, shine_bounds))
	shine_material.set_shader_parameter("shine_width", shine_width)
	shine_material.set_shader_parameter("shine_position", 0.0)
	return shine_material


func _apply_pack_data() -> void:
	var data: BoosterPackData = pack_data as BoosterPackData
	if not data:
		return
	price_stat.value = data.price
	price_stat.fill_color = PRICE_COLOR
	pack_letter.add_theme_color_override("font_color", data.pack_color)
	pack_letter.add_theme_color_override("font_outline_color", data.accent_color)
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = data.pack_color
	background_style.border_color = DARK_COLOR
	background_style.set_border_width_all(4)
	background_style.set_corner_radius_all(8)
	pack_background.add_theme_stylebox_override("panel", background_style)
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color.TRANSPARENT
	inner_style.border_color = data.accent_color
	inner_style.set_border_width_all(2)
	inner_style.set_corner_radius_all(8)
	inner_outline.add_theme_stylebox_override("panel", inner_style)


func get_price_stat() -> StatCircle:
	return price_stat


func _get_shine_bounds() -> Rect2:
	var bounds: Rect2 = Rect2(Vector2.ZERO, size)
	var price_rect: Rect2 = Rect2(price_stat.position, price_stat.size)
	return bounds.merge(price_rect)


func _get_shine_circle(stat: Control, shine_bounds: Rect2) -> Vector3:
	var center: Vector2 = stat.position + stat.size * 0.5 - shine_bounds.position
	var radius: float = maxf(stat.size.x, stat.size.y) * 0.5
	return Vector3(center.x, center.y, radius)


func _rect_to_vector4(rect: Rect2) -> Vector4:
	return Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y)
