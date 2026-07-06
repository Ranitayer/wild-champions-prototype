class_name BattleBoardSnapshot
extends RefCounted

const CARD_ID := "card_id"
const TEAM := "team"
const SLOT_INDEX := "slot_index"
const TIER := "tier"

var cards: Array[Dictionary] = []


static func from_arena(arena: BattleArena) -> BattleBoardSnapshot:
	var snapshot := BattleBoardSnapshot.new()
	for slot in arena.get_all_slots():
		var card := slot.get_card()
		if not card or not card.card_data:
			continue
		snapshot.add_card(card.card_data, slot.team, slot.slot_index, card.get_card_tier())
	return snapshot


func add_card(card_data: CardData, team: int, slot_index: int, tier: int) -> void:
	if not card_data or card_data.resource_path.is_empty():
		return
	cards.append({
		CARD_ID: card_data.resource_path,
		TEAM: team,
		SLOT_INDEX: slot_index,
		TIER: tier,
	})


func is_empty() -> bool:
	return cards.is_empty()


func to_states() -> Array[BattleCardState]:
	var states: Array[BattleCardState] = []
	var next_id := 0
	for entry in cards:
		var card_data := load(str(entry[CARD_ID])) as CardData
		if not card_data:
			continue
		states.append(BattleCardState.new(
			next_id,
			card_data,
			int(entry[TEAM]),
			int(entry[SLOT_INDEX]),
			int(entry[TIER])
		))
		next_id += 1
	return states


func to_network_payload() -> Array[Dictionary]:
	var payload: Array[Dictionary] = []
	for entry in cards:
		payload.append(entry.duplicate(true))
	return payload


static func from_network_payload(payload: Array) -> BattleBoardSnapshot:
	var snapshot := BattleBoardSnapshot.new()
	for value in payload:
		var entry: Dictionary = value as Dictionary
		if entry.is_empty():
			continue
		if not entry.has(CARD_ID) or not entry.has(TEAM) or not entry.has(SLOT_INDEX) or not entry.has(TIER):
			continue
		snapshot.cards.append({
			CARD_ID: str(entry[CARD_ID]),
			TEAM: int(entry[TEAM]),
			SLOT_INDEX: int(entry[SLOT_INDEX]),
			TIER: int(entry[TIER]),
		})
	return snapshot
