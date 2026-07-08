class_name AfterKillAttackHealthBuffEffect
extends CardEffect

@export_range(1, 99, 1) var amount := 2


func apply_after_kill(
	source: BattleCardState,
	_defeated_target: BattleCardState,
	_cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	if not source.is_alive():
		return
	_apply_stat_buff(source, "attack", source.add_permanent_attack(amount), events)
	_apply_stat_buff(source, "health", source.add_permanent_health(amount), events)


func _apply_stat_buff(
	source: BattleCardState,
	stat: String,
	result: int,
	events: Array[BattleEvent]
) -> void:
	BattleEvent.add(events, BattleEvent.BUFF_APPLIED, {
		"source_id": source.card_id,
		"target_id": source.card_id,
		"stat": stat,
		"amount": amount,
		"result": result,
	})
