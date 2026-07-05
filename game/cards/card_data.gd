class_name CardData
extends Resource

const MAX_TIER := 3

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	MYTHIC,
}

@export var title: String = "CARD TITLE"
@export_multiline var description: String = "Card description."
@export var art: Texture2D
@export_range(0.1, 4.0, 0.05) var art_scale := 1.0
@export var art_offset := Vector2.ZERO
@export var rarity: Rarity = Rarity.COMMON
@export_range(1, MAX_TIER, 1) var tier := 1
@export_range(0, 999, 1) var attack: int = 0
@export_range(0, 999, 1) var health: int = 0
@export_range(0, 99, 1) var cooldown: int = 0
@export var effects: Array[Resource] = []
@export var traits: Array[Resource] = []
