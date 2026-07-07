@tool
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
@export var tags: Array[StringName] = []
@export_range(1, MAX_TIER, 1) var tier := 1
@export_range(0, 999, 1) var attack: int = 0
@export_range(0, 999, 1) var health: int = 0
@export_range(0, 99, 1) var cooldown: int = 0
@export var effects: Array[Resource] = []
@export var traits: Array[Resource] = []
@export var tier_overrides: Array[Resource] = []


func get_max_tier() -> int:
	return 2 if rarity >= Rarity.EPIC else MAX_TIER


func get_attack(card_tier: int) -> int:
	var tier_data := _get_tier_override(card_tier)
	return tier_data.attack if tier_data else attack


func get_health(card_tier: int) -> int:
	var tier_data := _get_tier_override(card_tier)
	return tier_data.health if tier_data else health


func get_description(card_tier: int) -> String:
	var tier_data := _get_tier_override(card_tier)
	if tier_data and not tier_data.description.is_empty():
		return tier_data.description
	return description


func get_effects(card_tier: int) -> Array[Resource]:
	var tier_data := _get_tier_override(card_tier)
	if tier_data and tier_data.replace_effects:
		return tier_data.effects
	return effects


func get_traits(card_tier: int) -> Array[Resource]:
	var tier_data := _get_tier_override(card_tier)
	if tier_data and tier_data.replace_traits:
		return tier_data.traits
	return traits


func _get_tier_override(card_tier: int) -> CardTierOverride:
	for override_resource in tier_overrides:
		var tier_data := override_resource as CardTierOverride
		if tier_data and tier_data.tier == card_tier:
			return tier_data
	return null
