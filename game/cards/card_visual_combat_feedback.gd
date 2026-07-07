class_name CardVisualCombatFeedback
extends RefCounted


static func play_attack_to_impact(card: CardVisual, target_center: Vector2) -> void:
	card._stop_tweens()
	card.attack_start_position = card.global_position
	card.attack_start_z_index = card.z_index
	var direction: Vector2 = (target_center - card.get_card_center()).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	var anticipation_position: Vector2 = card.attack_start_position - direction * card.attack_anticipation_distance
	var charge_distance: float = (
		card._get_visual_radius_along(direction, card.attack_scale)
		+ card._get_visual_radius_along(-direction, 1.0)
		+ card.attack_impact_margin
	)
	var charge_position: Vector2 = target_center - direction * charge_distance - card.card_size * 0.5
	var aim_rotation: float = clampf(
		direction.x * card.attack_aim_rotation_degrees,
		-card.attack_aim_rotation_degrees,
		card.attack_aim_rotation_degrees
	)

	card.z_index = CardVisual.COMBAT_Z_INDEX
	card._motion_tween = card.create_tween()
	card._motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card._motion_tween.tween_property(card, "global_position", anticipation_position, card.attack_anticipation_duration)
	card._motion_tween.parallel().tween_property(card.card_surface, "scale", Vector2.ONE * card.attack_scale, card.attack_anticipation_duration)
	card._motion_tween.parallel().tween_property(card.card_surface, "rotation_degrees", aim_rotation, card.attack_anticipation_duration)
	card._motion_tween.tween_property(card, "global_position", charge_position, card.attack_charge_duration).set_trans(Tween.TRANS_BACK)
	await card._motion_tween.finished


static func start_attack_return(card: CardVisual) -> void:
	card.attack_returning = true
	card._motion_tween = card.create_tween()
	card._motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card._motion_tween.tween_property(card, "global_position", card.attack_start_position, card.attack_return_duration)
	card._motion_tween.parallel().tween_property(card.card_surface, "scale", Vector2.ONE, card.attack_return_duration)
	card._motion_tween.parallel().tween_property(card.card_surface, "rotation_degrees", 0.0, card.attack_return_duration)
	card._motion_tween.finished.connect(Callable(card, "_on_attack_return_finished"))


static func start_hit_animation(
	card: CardVisual,
	attacker_center: Vector2,
	accent_color: Color = CardVisual.ORANGE_COLOR
) -> Tween:
	card._stop_tweens()
	card.visual_group.material = card._hit_flash_material
	flash_hit(card, accent_color)
	var start_position: Vector2 = card.card_surface.position
	var knockback_direction: Vector2 = (card.get_card_center() - attacker_center).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.DOWN
	var shake_direction: Vector2 = Vector2(-knockback_direction.y, knockback_direction.x)
	var knockback_position: Vector2 = start_position + knockback_direction * card.hit_knockback_distance

	card._motion_tween = card.create_tween()
	card._motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card._motion_tween.tween_property(card.card_surface, "position", knockback_position, card.hit_duration * 0.35)
	for shake_index in range(card.hit_shake_count):
		var shake_sign: float = -1.0 if shake_index % 2 == 0 else 1.0
		var shake_position: Vector2 = knockback_position + shake_direction * card.hit_shake_distance * shake_sign
		card._motion_tween.tween_property(card.card_surface, "position", shake_position, card.hit_duration / maxf(1.0, float(card.hit_shake_count)))
		card._motion_tween.parallel().tween_property(card.card_surface, "rotation_degrees", card.hit_rotation_shake_degrees * shake_sign, card.hit_duration / maxf(1.0, float(card.hit_shake_count)))
	card._motion_tween.tween_property(card.card_surface, "position", start_position, card.hit_duration * 0.35)
	card._motion_tween.parallel().tween_property(card.card_surface, "rotation_degrees", 0.0, card.hit_duration * 0.35)
	return card._motion_tween


static func play_death_effect_windup(card: CardVisual, effect_color: Color) -> void:
	card._stop_tweens()
	card.z_index = CardVisual.COMBAT_Z_INDEX
	card.show_effect_outline(effect_color, card.death_effect_windup_duration)
	var start_position: Vector2 = card.card_surface.position
	card._motion_tween = card.create_tween().set_parallel(true)
	card._motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card._motion_tween.tween_property(
		card.card_surface,
		"position",
		start_position + Vector2.UP * card.death_effect_lift,
		card.death_effect_windup_duration
	)
	card._motion_tween.tween_property(
		card.card_surface,
		"scale",
		Vector2.ONE * card.death_effect_scale,
		card.death_effect_windup_duration
	)
	card._motion_tween.tween_property(
		card.card_surface,
		"rotation_degrees",
		card.death_effect_rotation_degrees,
		card.death_effect_windup_duration
	)
	await card._motion_tween.finished
	await card.get_tree().create_timer(card.death_effect_hold_duration).timeout
	await play_flash_pulses(card, Color.WHITE, 2)


static func play_death_animation(card: CardVisual, fly_direction: Vector2) -> void:
	card.clear_effect_outline()
	card._stop_tweens()
	card.z_index = CardVisual.COMBAT_Z_INDEX
	var direction: Vector2 = fly_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	_prepare_death_burn(card)

	var start_position: Vector2 = card.card_surface.position
	var rotation_sign: float = -1.0 if direction.y < 0.0 else 1.0
	card._motion_tween = card.create_tween().set_parallel(true)
	card._motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	card._motion_tween.tween_property(
		card.card_surface,
		"position",
		start_position + direction * card.death_animation_distance,
		card.death_animation_duration
	)
	card._motion_tween.tween_property(
		card.card_surface,
		"scale",
		Vector2.ONE * card.death_animation_scale,
		card.death_animation_duration
	)
	card._motion_tween.tween_property(
		card.card_surface,
		"rotation_degrees",
		card.death_animation_rotation_degrees * rotation_sign,
		card.death_animation_duration
	)
	card._motion_tween.tween_method(
		Callable(card, "_set_death_burn_value"),
		0.0,
		1.0,
		card.death_animation_duration
	)
	await card._motion_tween.finished


static func play_dissolve_animation(card: CardVisual) -> void:
	card.clear_effect_outline()
	card._stop_tweens()
	card.z_index = CardVisual.COMBAT_Z_INDEX
	_prepare_death_burn(card)
	card._motion_tween = card.create_tween()
	card._motion_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	card._motion_tween.tween_method(
		Callable(card, "_set_death_burn_value"),
		0.0,
		1.0,
		card.death_animation_duration
	)
	await card._motion_tween.finished


static func play_sell_drop(card: CardVisual, target_global_position: Vector2) -> void:
	card.clear_effect_outline()
	card._stop_tweens()
	card._hovered = false
	card._snapping = true
	card.z_index = CardVisual.DRAG_Z_INDEX
	if card._trait_tooltip:
		card._trait_tooltip.hide()
	card._motion_tween = card.create_tween().set_parallel(true)
	card._motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card._motion_tween.tween_property(card, "global_position", target_global_position, card.snap_duration)
	card._motion_tween.tween_property(card.card_surface, "position", Vector2.ZERO, card.snap_duration)
	card._motion_tween.tween_property(card.card_surface, "scale", Vector2.ONE, card.snap_duration)
	card._motion_tween.tween_property(card.card_surface, "rotation_degrees", 0.0, card.snap_duration)
	await card._motion_tween.finished


static func play_survival_animation(card: CardVisual) -> void:
	card._stop_tweens()
	var step_duration: float = card.survival_sway_duration / float(card.survival_sway_count + 1)
	card._motion_tween = card.create_tween()
	card._motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for sway_index in range(card.survival_sway_count):
		var sway_sign: float = -1.0 if sway_index % 2 == 0 else 1.0
		card._motion_tween.tween_property(
			card.card_surface,
			"rotation_degrees",
			card.survival_rotation_degrees * sway_sign,
			step_duration
		)
		if sway_index == 0:
			card._motion_tween.parallel().tween_property(
				card.card_surface,
				"scale",
				Vector2.ONE * card.survival_pop_scale,
				step_duration
			)
	card._motion_tween.tween_property(card.card_surface, "rotation_degrees", 0.0, step_duration)
	card._motion_tween.parallel().tween_property(card.card_surface, "scale", Vector2.ONE, step_duration)
	await card._motion_tween.finished


static func play_dodge_animation(card: CardVisual, direction: float) -> void:
	card._stop_tweens()
	var dodge_sign: float = signf(direction)
	if dodge_sign == 0.0:
		dodge_sign = 1.0
	var start_position: Vector2 = card.card_surface.position
	var half_duration: float = card.dodge_duration * 0.5
	card._motion_tween = card.create_tween()
	card._motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card._motion_tween.tween_property(
		card.card_surface,
		"position:x",
		start_position.x + card.dodge_distance * dodge_sign,
		half_duration
	)
	card._motion_tween.parallel().tween_property(
		card.card_surface,
		"rotation_degrees",
		card.dodge_rotation_degrees * dodge_sign,
		half_duration
	)
	card._motion_tween.tween_property(card.card_surface, "position:x", start_position.x, half_duration)
	card._motion_tween.parallel().tween_property(card.card_surface, "rotation_degrees", 0.0, half_duration)
	await card._motion_tween.finished


static func flash_hit(card: CardVisual, accent_color: Color = CardVisual.ORANGE_COLOR) -> void:
	if card._flash_tween:
		card._flash_tween.kill()
	if card._buff_tween:
		card._buff_tween.kill()
	card._set_hit_flash_color(Color.WHITE)
	card._set_hit_flash_strength(1.0)
	card._flash_tween = card.create_tween()
	card._flash_tween.tween_interval(card.hit_flash_duration)
	card._flash_tween.tween_callback(Callable(card, "_set_hit_flash_color").bind(accent_color))
	card._flash_tween.tween_interval(card.hit_orange_duration)
	card._flash_tween.tween_method(Callable(card, "_set_hit_flash_strength"), 1.0, 0.0, card.hit_flash_duration)


static func play_flash_pulses(card: CardVisual, color: Color, count: int) -> void:
	if card._flash_tween:
		card._flash_tween.kill()
	if card._buff_tween:
		card._buff_tween.kill()
	card.visual_group.material = card._hit_flash_material
	card._set_hit_flash_color(color)
	card._flash_tween = card.create_tween()
	for flash_index in range(maxi(1, count)):
		card._flash_tween.tween_callback(Callable(card, "_set_hit_flash_strength").bind(1.0))
		card._flash_tween.tween_interval(card.hit_flash_duration)
		card._flash_tween.tween_callback(Callable(card, "_set_hit_flash_strength").bind(0.0))
		if flash_index < count - 1:
			card._flash_tween.tween_interval(card.hit_flash_duration)
	await card._flash_tween.finished
	card._flash_tween = null


static func set_hit_flash_color(card: CardVisual, color: Color) -> void:
	card.visual_group.material = card._hit_flash_material
	var flash_material: ShaderMaterial = card.visual_group.material as ShaderMaterial
	if flash_material:
		flash_material.set_shader_parameter("flash_color", color)


static func set_hit_flash_strength(card: CardVisual, strength: float) -> void:
	card.visual_group.material = card._hit_flash_material
	var flash_material: ShaderMaterial = card.visual_group.material as ShaderMaterial
	if flash_material:
		flash_material.set_shader_parameter("flash_strength", strength)


static func configure_materials(card: CardVisual) -> void:
	card._hit_flash_material = card.visual_group.material as ShaderMaterial
	if card._hit_flash_material:
		card._hit_flash_material = card._hit_flash_material.duplicate() as ShaderMaterial
		card.visual_group.material = card._hit_flash_material
	card._death_burn_material = ShaderMaterial.new()
	card._death_burn_material.shader = CardVisual.DEATH_BURN_SHADER
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 91013
	noise.frequency = 0.045
	var dissolve_texture: NoiseTexture2D = NoiseTexture2D.new()
	dissolve_texture.width = 128
	dissolve_texture.height = 128
	dissolve_texture.seamless = true
	dissolve_texture.noise = noise
	card._death_burn_material.set_shader_parameter("dissolve_texture", dissolve_texture)
	_apply_death_burn_parameters(card)


static func _apply_death_burn_parameters(card: CardVisual) -> void:
	if not card._death_burn_material:
		return
	card._death_burn_material.set_shader_parameter("burn_color", card.death_burn_color)
	card._death_burn_material.set_shader_parameter("burn_size", card.death_burn_size)
	card._death_burn_material.set_shader_parameter("edge_softness", card.death_burn_edge_softness)
	card._death_burn_material.set_shader_parameter("noise_strength", card.death_burn_noise_strength)
	card._death_burn_material.set_shader_parameter("noise_scale", card.death_burn_noise_scale)
	card._death_burn_material.set_shader_parameter("dissolve_direction", card.death_burn_direction)


static func _prepare_death_burn(card: CardVisual) -> void:
	if not card._death_burn_material:
		configure_materials(card)
	_apply_death_burn_parameters(card)
	card.visual_group.material = card._death_burn_material
	card._set_death_burn_value(0.0)


static func clear_death_burn_materials(card: CardVisual) -> void:
	card.visual_group.material = card._hit_flash_material
