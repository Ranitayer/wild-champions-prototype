class_name AfterAttackedAttackBuffEffect
extends CardEffect

@export_range(1, 99, 1) var amount := 1


func apply_after_attacked(
	_source: BattleCardState,
	target: BattleCardState,
	_damage: int,
	_cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	if not target.is_alive():
		return
	var result: int = target.add_permanent_attack(amount)
	BattleEvent.add(events, BattleEvent.BUFF_APPLIED, {
		"source_id": target.card_id,
		"target_id": target.card_id,
		"stat": "attack",
		"amount": amount,
		"result": result,
	})
