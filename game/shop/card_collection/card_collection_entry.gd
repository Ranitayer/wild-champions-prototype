class_name CardCollectionEntry
extends RefCounted

var id := 0
var data: CardData
var tier := 1


func _init(entry_id: int = 0, card_data: CardData = null, card_tier: int = 1) -> void:
	id = entry_id
	data = card_data
	tier = card_tier


func duplicate_entry() -> CardCollectionEntry:
	return CardCollectionEntry.new(id, data, tier)
