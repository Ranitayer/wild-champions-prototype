@tool
class_name PredatorTrait
extends CardTrait


func _init() -> void:
	trait_id = &"predator"
	display_name = "Predator"
	show_value = false
	tooltip_description = "Attacks the lowest Health enemy."


func uses_lowest_health_target(_trait_value: int) -> bool:
	return true
