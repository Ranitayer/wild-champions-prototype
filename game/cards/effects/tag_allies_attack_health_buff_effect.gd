class_name TagAlliesAttackHealthBuffEffect
extends CardEffect

@export var target_tag: StringName = &""
@export_range(1, 99, 1) var amount := 1


func apply_start_of_combat(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	for target in cards:
		if target == source or target.team != source.team or not target.is_alive():
			continue
		if not target.data.tags.has(target_tag):
			continue
		_apply_stat_buff(source, target, "attack", target.add_permanent_attack(amount), events)
		_apply_stat_buff(source, target, "health", target.add_permanent_health(amount), events)


func _apply_stat_buff(
	source: BattleCardState,
	target: BattleCardState,
	stat: String,
	result: int,
	events: Array[BattleEvent]
) -> void:
	BattleEvent.add(events, BattleEvent.BUFF_APPLIED, {
		"source_id": source.card_id,
		"target_id": target.card_id,
		"stat": stat,
		"amount": amount,
		"result": result,
	})
