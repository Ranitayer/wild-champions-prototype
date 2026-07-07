class_name EveryNthAttackDoubleEffect
extends CardEffect

@export_range(2, 99, 1) var attack_interval := 2


func apply_before_attack(
	source: BattleCardState,
	_target: BattleCardState,
	_cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	if source.attacks_made % attack_interval != 0:
		return
	var amount := source.attack
	var result := source.add_temporary_attack(amount, 1)
	BattleEvent.add(events, BattleEvent.TEMPORARY_ATTACK_APPLIED, {
		"source_id": source.card_id,
		"target_id": source.card_id,
		"amount": amount,
		"result": result,
	})


func get_attack_cycle_length() -> int:
	return attack_interval
