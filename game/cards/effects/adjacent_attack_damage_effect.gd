class_name AdjacentAttackDamageEffect
extends CardEffect

@export_range(1, 99, 1) var damage := 1


func get_adjacent_attack_damage(
	_source: BattleCardState,
	_target: BattleCardState,
	_cards: Array[BattleCardState]
) -> int:
	return damage
