@tool
class_name FearTrait
extends CardTrait


func _init() -> void:
	trait_id = &"fear"
	display_name = "Fear"
	show_value = false
	tooltip_description = "Enemies with 2 Attack or less cannot attack this card."


func blocks_attacker_attack(attacker_attack: int, _trait_value: int) -> bool:
	return attacker_attack <= 2
