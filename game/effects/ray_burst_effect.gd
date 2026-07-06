class_name RayBurstEffect
extends ColorRect

const SUNBURST_SHADER: Shader = preload("res://game/effects/shaders/sunburst_rays.gdshader")

@export var ray_color := Color(0.870588, 0.619608, 0.254902, 0.55)
@export_range(3, 16, 1) var ray_count := 6
@export_range(0.05, 0.95, 0.01) var ray_width := 0.38
@export_range(0.001, 0.2, 0.001) var edge_softness := 0.02
@export_range(0.2, 3.0, 0.05) var rotation_speed := 0.55
@export_range(0.0, 1.5, 0.01) var outer_radius := 1.0
@export_range(0.1, 4.0, 0.1) var fade_power := 1.5

var _effect_material: ShaderMaterial
var _rotation := 0.0
var _base_ray_color := Color.WHITE
var _base_rotation_speed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	_base_ray_color = ray_color
	_base_rotation_speed = rotation_speed
	_effect_material = ShaderMaterial.new()
	_effect_material.shader = SUNBURST_SHADER
	material = _effect_material
	_center_on_parent()
	_apply_parameters()
	stop()


func _process(delta: float) -> void:
	_rotation = fmod(_rotation + delta * rotation_speed, TAU)
	_effect_material.set_shader_parameter("rotation", _rotation)


func start() -> void:
	_center_on_parent()
	_apply_parameters()
	show()
	set_process(true)


func stop() -> void:
	hide()
	set_process(false)


func set_runtime_settings(next_color: Color, next_rotation_speed: float) -> void:
	ray_color = next_color
	rotation_speed = next_rotation_speed
	_apply_parameters()


func reset_runtime_settings() -> void:
	ray_color = _base_ray_color
	rotation_speed = _base_rotation_speed
	_apply_parameters()


func _center_on_parent() -> void:
	var parent_control := get_parent() as Control
	if parent_control:
		position = (parent_control.size - size) * 0.5


func _apply_parameters() -> void:
	if not _effect_material:
		return
	_effect_material.set_shader_parameter("ray_color", ray_color)
	_effect_material.set_shader_parameter("ray_count", ray_count)
	_effect_material.set_shader_parameter("ray_width", ray_width)
	_effect_material.set_shader_parameter("edge_softness", edge_softness)
	_effect_material.set_shader_parameter("outer_radius", outer_radius)
	_effect_material.set_shader_parameter("fade_power", fade_power)
