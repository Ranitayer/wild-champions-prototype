class_name BattleBlockEffect
extends Node

const SHARP_SHINE_SHADER := preload("res://game/battle/effects/shaders/sharp_shine.gdshader")

@export_range(0.05, 1.0, 0.01) var duration := 0.36
@export_range(0.01, 0.5, 0.01) var shine_width := 0.11
@export_range(0.0, 4.0, 0.1) var brightness := 1.5
@export_range(-90.0, 90.0, 1.0) var rotation_degrees := -28.0

var edge_softness := 0.012
var overlay_z_index := 1000


func play(target: CardVisual) -> void:
	if not is_instance_valid(target):
		return
	var overlay := ColorRect.new()
	overlay.name = "BlockShineOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color.WHITE
	overlay.position = target.get_card_effect_position()
	overlay.size = target.get_card_effect_size()
	overlay.z_index = overlay_z_index
	overlay.material = _create_material(overlay.size, target.get_card_effect_mask_data())
	target.get_card_effect_parent().add_child(overlay)

	var tween := overlay.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_shine_position.bind(overlay), 0.0, 1.0, duration)
	await tween.finished
	overlay.queue_free()


func _create_material(overlay_size: Vector2, mask_data: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHARP_SHINE_SHADER
	material.set_shader_parameter("shine_width", shine_width)
	material.set_shader_parameter("edge_softness", edge_softness)
	material.set_shader_parameter("brightness", brightness)
	material.set_shader_parameter("rotation_degrees", rotation_degrees)
	material.set_shader_parameter("overlay_size", overlay_size)
	var card_rect = mask_data["card_rect"]
	var title_rect = mask_data["title_rect"]
	material.set_shader_parameter("card_rect", _rect_to_vector4(card_rect))
	material.set_shader_parameter("card_radius", float(mask_data["card_radius"]))
	material.set_shader_parameter("title_rect", _rect_to_vector4(title_rect))
	material.set_shader_parameter("title_radius", float(mask_data["title_radius"]))
	material.set_shader_parameter("attack_circle", mask_data["attack_circle"])
	material.set_shader_parameter("temporary_attack_circle", mask_data["temporary_attack_circle"])
	material.set_shader_parameter("health_circle", mask_data["health_circle"])
	material.set_shader_parameter("poison_circle", mask_data["poison_circle"])
	material.set_shader_parameter("cooldown_circle", mask_data["cooldown_circle"])
	material.set_shader_parameter("shine_position", 0.0)
	return material


func _rect_to_vector4(rect) -> Vector4:
	return Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y)


func _set_shine_position(position: float, overlay: ColorRect) -> void:
	if not is_instance_valid(overlay):
		return
	var material := overlay.material as ShaderMaterial
	if material:
		material.set_shader_parameter("shine_position", position)
