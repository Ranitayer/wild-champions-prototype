class_name CardData
extends Resource

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	MYTHIC,
}

@export var title: String = "CARD TITLE"
@export_multiline var description: String = "Card description."
@export var rarity: Rarity = Rarity.COMMON
@export_range(0, 999, 1) var attack: int = 0
@export_range(0, 999, 1) var health: int = 0
@export_range(0, 99, 1) var cooldown: int = 0
