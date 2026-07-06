class_name OverwhelmTrait
extends CardTrait


func _init() -> void:
	trait_id = &"overwhelm"
	display_name = "Overwhelm"
	show_value = false
	tooltip_description = "Excess attack damage spills evenly to adjacent enemies."


func get_attack_overflow_damage(
	damage: int,
	target_health_before: int,
	target_survived: bool,
	_trait_value: int
) -> int:
	if target_survived:
		return 0
	return maxi(0, damage - target_health_before)


func get_trigger_color_hex() -> String:
	return "a53030"
