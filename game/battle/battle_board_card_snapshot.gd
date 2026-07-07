class_name BattleBoardCardSnapshot
extends RefCounted

const CARD_ID := "card_id"
const TEAM := "team"
const SLOT_INDEX := "slot_index"
const TIER := "tier"

var card_id := ""
var team := 0
var slot_index := 0
var tier := 1


func _init(card_resource_path: String = "", card_team: int = 0, card_slot_index: int = 0, card_tier: int = 1) -> void:
	card_id = card_resource_path
	team = card_team
	slot_index = card_slot_index
	tier = card_tier


func to_dictionary() -> Dictionary:
	return {
		CARD_ID: card_id,
		TEAM: team,
		SLOT_INDEX: slot_index,
		TIER: tier,
	}


static func from_dictionary(entry: Dictionary) -> BattleBoardCardSnapshot:
	if (
		entry.is_empty()
		or not entry.has(CARD_ID)
		or not entry.has(SLOT_INDEX)
		or not entry.has(TIER)
	):
		return null
	return BattleBoardCardSnapshot.new(
		str(entry[CARD_ID]),
		int(entry.get(TEAM, 0)),
		int(entry[SLOT_INDEX]),
		int(entry[TIER])
	)
