@tool
class_name ThornsTrait
extends CardTrait


func _init() -> void:
	trait_id = &"thorns"
	display_name = "Thorns"
	tooltip_description = "When attacked, deals damage back to the attacker."


func get_tooltip_description(trait_value := -1) -> String:
	var displayed_value := value if trait_value < 0 else trait_value
	return "When attacked, deals %d damage back." % maxi(1, displayed_value)


func get_return_attack_damage(trait_value: int) -> int:
	return maxi(0, trait_value)


func get_trigger_color_hex() -> String:
	return "94bd6b"
