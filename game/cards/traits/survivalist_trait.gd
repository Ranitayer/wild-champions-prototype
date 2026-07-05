class_name SurvivalistTrait
extends CardTrait


func _init() -> void:
	trait_id = &"survivalist"
	display_name = "Survivalist"
	show_value = false
	tooltip_description = "The first time this card would die, it survives with 1 HP and removes negative effects."


func get_lethal_survival_health(_trait_value: int) -> int:
	return 1


func clears_negative_effects_on_survival() -> bool:
	return true


func get_trigger_color_hex() -> String:
	return "a53030"
