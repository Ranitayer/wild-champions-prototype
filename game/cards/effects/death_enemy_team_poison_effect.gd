class_name DeathEnemyTeamPoisonEffect
extends CardEffect

@export_range(1, 99, 1) var amount := 1
@export var effect_color: Color = Color("b0e535")


func apply_on_death(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	BattleEvent.add(events, BattleEvent.DEATH_EFFECT_TRIGGERED, {
		"card_id": source.card_id,
		"effect_color": effect_color.to_html(false),
	})
	var results: Dictionary = {}
	for target in cards:
		if target.team == source.team or not target.is_alive():
			continue
		target.poison += amount
		results[target.card_id] = target.poison
	if results.is_empty():
		return
	BattleEvent.add(events, BattleEvent.POISON_GROUP_APPLIED, {
		"source_id": source.card_id,
		"amount": amount,
		"results": results,
		"flash_color": effect_color.to_html(false),
		"source_dies_after_effect": true,
	})
