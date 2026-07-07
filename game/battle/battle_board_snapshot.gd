class_name BattleBoardSnapshot
extends RefCounted

var cards: Array[BattleBoardCardSnapshot] = []


static func from_arena(arena: BattleArena) -> BattleBoardSnapshot:
	var snapshot := BattleBoardSnapshot.new()
	for slot in arena.get_all_slots():
		var card: CardVisual = slot.get_card()
		if not card or not card.card_data:
			continue
		if card.get_current_slot() != slot:
			continue
		snapshot.add_card(card.card_data, slot.team, slot.slot_index, card.get_card_tier())
	return snapshot


func add_card(card_data: CardData, team: int, slot_index: int, tier: int) -> void:
	if not card_data or card_data.resource_path.is_empty():
		return
	cards.append(BattleBoardCardSnapshot.new(card_data.resource_path, team, slot_index, tier))


func is_empty() -> bool:
	return cards.is_empty()


func to_states() -> Array[BattleCardState]:
	var states: Array[BattleCardState] = []
	var next_id := 0
	for entry in cards:
		var card_data := load(entry.card_id) as CardData
		if not card_data:
			continue
		states.append(BattleCardState.new(
			next_id,
			card_data,
			entry.team,
			entry.slot_index,
			entry.tier
		))
		next_id += 1
	return states


func to_network_payload(team_filter: int = -1) -> Array[BattleBoardCardSnapshot]:
	var payload: Array[BattleBoardCardSnapshot] = []
	for entry in cards:
		if team_filter >= 0 and entry.team != team_filter:
			continue
		payload.append(BattleBoardCardSnapshot.new(entry.card_id, entry.team, entry.slot_index, entry.tier))
	return payload


func append_payload_as_team(payload: Array, team: int) -> void:
	for value in payload:
		var entry := _payload_entry(value)
		if not entry:
			continue
		cards.append(BattleBoardCardSnapshot.new(entry.card_id, team, entry.slot_index, entry.tier))


static func from_network_payload(payload: Array) -> BattleBoardSnapshot:
	var snapshot := BattleBoardSnapshot.new()
	for value in payload:
		var entry := _payload_entry(value)
		if not entry:
			continue
		snapshot.cards.append(entry)
	return snapshot


static func to_rpc_payload(payload: Array[BattleBoardCardSnapshot]) -> Array:
	var result: Array = []
	for entry in payload:
		if entry:
			result.append(entry.to_dictionary())
	return result


static func _payload_entry(value: Variant) -> BattleBoardCardSnapshot:
	if value is BattleBoardCardSnapshot:
		var snapshot_entry: BattleBoardCardSnapshot = value
		return snapshot_entry
	if value is Dictionary:
		var dictionary: Dictionary = value
		return BattleBoardCardSnapshot.from_dictionary(dictionary)
	return null
