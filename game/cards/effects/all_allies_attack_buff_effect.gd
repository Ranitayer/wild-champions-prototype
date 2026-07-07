class_name AllAlliesAttackBuffEffect
extends CardEffect

@export_range(1, 99, 1) var amount := 1


func apply_start_of_combat(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	for target in cards:
		if target == source or target.team != source.team or not target.is_alive():
			continue
		var result := target.add_permanent_attack(amount)
		BattleEvent.add(events, BattleEvent.BUFF_APPLIED, {
			"source_id": source.card_id,
			"target_id": target.card_id,
			"stat": "attack",
			"amount": amount,
			"result": result,
		})
