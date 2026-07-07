class_name DeathEnemyTeamDamageEffect
extends CardEffect

@export_range(0, 99, 1) var damage := 1
@export var use_half_attack := false
@export var effect_color := Color("6000ff")


func apply_on_death(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	var amount: int = damage
	if use_half_attack:
		amount = ceili(float(source.attack) * 0.5)
	if amount <= 0:
		return
	BattleEvent.add(events, BattleEvent.DEATH_EFFECT_TRIGGERED, {
		"card_id": source.card_id,
		"effect_color": effect_color.to_html(false),
	})
	var hits: Array[BattleEffectHit] = []
	for target in cards:
		if target.team == source.team or not target.is_alive():
			continue
		target.health -= amount
		hits.append(BattleEffectHit.new(target.card_id, amount, target.health))
	if hits.is_empty():
		return
	BattleEvent.add(events, BattleEvent.EFFECT_DAMAGE_GROUP, {
		"source_id": source.card_id,
		"hits": hits,
		"flash_color": effect_color.to_html(false),
		"source_dies_after_effect": true,
	})
