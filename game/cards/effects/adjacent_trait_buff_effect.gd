class_name AdjacentTraitBuffEffect
extends CardEffect

@export var trait_resource: CardTrait
@export_range(1, 99, 1) var amount := 1


func apply_start_of_combat(
	source: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[BattleEvent]
) -> void:
	if not trait_resource:
		return
	for target in cards:
		if target.team != source.team or not target.is_alive():
			continue
		if absi(target.slot_index - source.slot_index) != 1:
			continue
		var result := target.acquire_trait(trait_resource, amount)
		BattleEvent.add(events, BattleEvent.TRAIT_APPLIED, {
			"source_id": source.card_id,
			"target_id": target.card_id,
			"trait_id": str(trait_resource.trait_id),
			"trait_name": trait_resource.display_name,
			"trait_display_text": trait_resource.get_display_text(result),
			"trait_description": trait_resource.get_tooltip_description(result),
			"amount": amount,
			"result": result,
			"effect_color": Color(trait_resource.get_trigger_color_hex()),
		})
