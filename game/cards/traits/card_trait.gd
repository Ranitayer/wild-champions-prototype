@tool
class_name CardTrait
extends Resource

var trait_id: StringName
var display_name := "Trait"
@export var value: int = 1
var show_value := true
var is_negative_effect := false
var tooltip_description := ""


func get_display_text(trait_value := -1) -> String:
	var displayed_value := value if trait_value < 0 else trait_value
	if not show_value:
		return display_name
	return "%s %d" % [display_name, clampi(displayed_value, 1, get_max_value())]


func get_tooltip_description(_trait_value := -1) -> String:
	return tooltip_description


func modify_incoming_attack_damage(damage: int, _trait_value: int) -> int:
	return damage


func get_attack_heal_amount(_damage_done: int, _trait_value: int) -> int:
	return 0


func get_outgoing_poison_amount(_trait_value: int) -> int:
	return 0


func get_return_attack_damage(_trait_value: int) -> int:
	return 0


func get_incoming_attack_miss_chance(_trait_value: int) -> float:
	return 0.0


func uses_lowest_health_target(_trait_value: int) -> bool:
	return false


func blocks_attacker_attack(_attacker_attack: int, _trait_value: int) -> bool:
	return false


func get_attack_overflow_damage(
	_damage: int,
	_target_health_before: int,
	_target_survived: bool,
	_trait_value: int
) -> int:
	return 0


func get_lethal_survival_health(_trait_value: int) -> int:
	return 0


func clears_negative_effects_on_survival() -> bool:
	return false


func get_trigger_color_hex() -> String:
	return "de9e41"


func get_max_value() -> int:
	return 5
