class_name FlyingTrait
extends CardTrait


func _init() -> void:
	trait_id = &"flying"
	display_name = "Flying"
	show_value = false
	tooltip_description = "Attacks against this card have a 1 in 4 chance to miss."


func get_incoming_attack_miss_chance(_trait_value: int) -> float:
	return 0.25


func get_trigger_color_hex() -> String:
	return "577277"
