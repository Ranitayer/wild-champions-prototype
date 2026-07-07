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


static func start_hit_animation(card: CardVisual, attacker_center: Vector2) -> Tween:
	card._stop_tweens()
	card.visual_group.material = card._hit_flash_material
	flash_hit(card)
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


static func flash_hit(card: CardVisual) -> void:
	if card._flash_tween:
		card._flash_tween.kill()
	if card._buff_tween:
		card._buff_tween.kill()
	card._set_hit_flash_color(Color.WHITE)
	card._set_hit_flash_strength(1.0)
	card._flash_tween = card.create_tween()
	card._flash_tween.tween_interval(card.hit_flash_duration)
	card._flash_tween.tween_callback(Callable(card, "_set_hit_flash_color").bind(CardVisual.ORANGE_COLOR))
	card._flash_tween.tween_interval(card.hit_orange_duration)
	card._flash_tween.tween_method(Callable(card, "_set_hit_flash_strength"), 1.0, 0.0, card.hit_flash_duration)


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
