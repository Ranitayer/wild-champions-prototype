@tool
class_name ToughTrait
extends CardTrait


func _init() -> void:
	trait_id = &"tough"
	display_name = "Tough"
	tooltip_description = "Reduces damage taken from attacks by this amount."


func modify_incoming_attack_damage(damage: int, trait_value: int) -> int:
	return maxi(0, damage - clampi(trait_value, 1, 5))
