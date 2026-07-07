class_name CardEffect
extends Resource


func apply_start_of_combat(
	_source: BattleCardState,
	_cards: Array[BattleCardState],
	_events: Array[BattleEvent]
) -> void:
	pass


func apply_before_attack(
	_source: BattleCardState,
	_target: BattleCardState,
	_cards: Array[BattleCardState],
	_events: Array[BattleEvent]
) -> void:
	pass


func get_attack_cycle_length() -> int:
	return 1
