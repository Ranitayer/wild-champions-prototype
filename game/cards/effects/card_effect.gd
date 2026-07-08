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


func apply_after_attacked(
	_source: BattleCardState,
	_target: BattleCardState,
	_damage: int,
	_cards: Array[BattleCardState],
	_events: Array[BattleEvent]
) -> void:
	pass


func apply_after_kill(
	_source: BattleCardState,
	_defeated_target: BattleCardState,
	_cards: Array[BattleCardState],
	_events: Array[BattleEvent]
) -> void:
	pass


func apply_on_death(
	_source: BattleCardState,
	_cards: Array[BattleCardState],
	_events: Array[BattleEvent]
) -> void:
	pass


func apply_on_death_with_rng(
	_source: BattleCardState,
	_cards: Array[BattleCardState],
	_events: Array[BattleEvent],
	_rng: RandomNumberGenerator
) -> void:
	pass


func get_adjacent_attack_damage(
	_source: BattleCardState,
	_target: BattleCardState,
	_cards: Array[BattleCardState]
) -> int:
	return 0


func get_execute_health_threshold(_source: BattleCardState) -> int:
	return 0


func get_attack_cycle_length() -> int:
	return 1
