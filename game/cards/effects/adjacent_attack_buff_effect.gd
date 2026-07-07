class_name AdjacentAttackBuffEffect
extends CardEffect

@export_range(1, 99, 1) var amount := 1
@export var bonus_tag: StringName = &""
@export_range(0, 99, 1) var bonus_amount := 0


func apply_start_of_combat(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	for target in cards:
		if target.team != source.team or not target.is_alive():
			continue
		if absi(target.slot_index - source.slot_index) != 1:
			continue
		var buff_amount: int = _get_buff_amount(target)
		var result := target.add_permanent_attack(buff_amount)
		BattleEvent.add(events, BattleEvent.BUFF_APPLIED, {
			"source_id": source.card_id,
			"target_id": target.card_id,
			"stat": "attack",
			"amount": buff_amount,
			"result": result,
		})


func _get_buff_amount(target: BattleCardState) -> int:
	if bonus_amount > 0 and not String(bonus_tag).is_empty() and target.data.tags.has(bonus_tag):
		return amount + bonus_amount
	return amount
