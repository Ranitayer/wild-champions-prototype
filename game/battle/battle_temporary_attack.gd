class_name BattleTemporaryAttack
extends RefCounted

var amount: int
var attacks_remaining: int


func _init(attack_amount: int, attack_uses: int) -> void:
	amount = maxi(0, attack_amount)
	attacks_remaining = maxi(1, attack_uses)


func consume_attack() -> bool:
	attacks_remaining -= 1
	return attacks_remaining <= 0
