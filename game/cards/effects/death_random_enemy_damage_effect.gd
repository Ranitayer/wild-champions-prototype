class_name DeathRandomEnemyDamageEffect
extends CardEffect

@export_range(1, 99, 1) var damage := 1
@export var effect_color := Color("c7cfcc")


func apply_on_death_with_rng(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent],
	rng: RandomNumberGenerator
) -> void:
	var living_enemies: Array[BattleCardState] = []
	for card in cards:
		if card.team != source.team and card.is_alive():
			living_enemies.append(card)
	if living_enemies.is_empty():
		return
	var target := living_enemies[rng.randi_range(0, living_enemies.size() - 1)]
	target.health -= damage
	BattleEvent.add(events, BattleEvent.DEATH_EFFECT_TRIGGERED, {
		"card_id": source.card_id,
		"effect_color": effect_color.to_html(false),
	})
	BattleEvent.add(events, BattleEvent.EFFECT_DAMAGE_GROUP, {
		"source_id": source.card_id,
		"hits": [BattleEffectHit.new(target.card_id, damage, target.health)],
		"flash_color": effect_color.to_html(false),
		"source_dies_after_effect": true,
	})
