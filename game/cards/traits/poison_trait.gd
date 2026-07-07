@tool
class_name PoisonTrait
extends CardTrait


func _init() -> void:
	trait_id = &"poison"
	display_name = "Poison"
	tooltip_description = "On attack, gives target Poison."


func get_tooltip_description(trait_value := -1) -> String:
	var displayed_value := value if trait_value < 0 else trait_value
	return "On attack, gives target +%d Poison." % maxi(1, displayed_value)


func get_outgoing_poison_amount(trait_value: int) -> int:
	return maxi(0, trait_value)


func get_max_value() -> int:
	return 2147483647
