@tool
class_name LifestealTrait
extends CardTrait


func _init() -> void:
	trait_id = &"lifesteal"
	display_name = "Lifesteal"
	show_value = false
	tooltip_description = "After attacking, heals for half the damage dealt."


func get_attack_heal_amount(damage_done: int, trait_value: int) -> int:
	return ceili(maxi(0, damage_done) * clampi(trait_value, 1, 5) * 0.5)
