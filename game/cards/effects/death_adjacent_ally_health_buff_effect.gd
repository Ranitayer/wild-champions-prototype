class_name DeathAdjacentAllyHealthBuffEffect
extends CardEffect

@export_range(1, 99, 1) var amount := 1


func apply_on_death(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	for target in cards:
		if target == source or target.team != source.team or not target.is_alive():
			continue
		if absi(target.slot_index - source.slot_index) != 1:
			continue
		var result := target.add_permanent_health(amount)
		BattleEvent.add(events, BattleEvent.BUFF_APPLIED, {
			"source_id": source.card_id,
			"target_id": target.card_id,
			"stat": "health",
			"amount": amount,
			"result": result,
		})
