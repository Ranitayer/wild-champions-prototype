class_name FloatingEffect
extends Node

@export var vertical_distance := 6.0
@export_range(0.0, 15.0, 0.1) var rotation_degrees := 1.5
@export_range(0.5, 10.0, 0.1) var cycle_duration := 2.4
@export_range(0.0, 1.0, 0.05) var blend_in_duration := 0.25

var _target: Control
var _base_position := Vector2.ZERO
var _base_rotation := 0.0
var _phase := 0.0
var _blend := 0.0


func _ready() -> void:
	set_process(false)


func start(target: Control = null) -> void:
	stop()
	_target = target if target else get_parent() as Control
	if not is_instance_valid(_target):
		return
	_base_position = _target.global_position
	_base_rotation = _target.rotation_degrees
	_phase = 0.0
	_blend = 0.0
	_apply_float()
	set_process(true)


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		stop()
		return
	_phase = fmod(_phase + delta * TAU / cycle_duration, TAU)
	if blend_in_duration <= 0.0:
		_blend = 1.0
	else:
		_blend = minf(1.0, _blend + delta / blend_in_duration)
	_apply_float()


func _apply_float() -> void:
	var offset: float = sin(_phase) * _blend
	_target.global_position.y = _base_position.y + offset * vertical_distance
	_target.rotation_degrees = _base_rotation + offset * rotation_degrees


func stop() -> void:
	set_process(false)
	if is_instance_valid(_target):
		_target.global_position = _base_position
		_target.rotation_degrees = _base_rotation
	_target = null
