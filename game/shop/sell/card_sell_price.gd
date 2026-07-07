class_name CardSellPrice
extends RefCounted

static func get_price(card_data: CardData, tier: int) -> int:
	if not card_data:
		return 0
	var safe_tier: int = maxi(1, tier)
	match card_data.rarity:
		CardData.Rarity.COMMON:
			return _price_for_tier(safe_tier, 1, 2, 4)
		CardData.Rarity.UNCOMMON:
			return _price_for_tier(safe_tier, 3, 6, 12)
		CardData.Rarity.RARE:
			return _price_for_tier(safe_tier, 5, 10, 20)
		CardData.Rarity.EPIC:
			return _price_for_tier(safe_tier, 10, 25, 25)
		CardData.Rarity.MYTHIC:
			return _price_for_tier(safe_tier, 15, 40, 40)
	return 0


static func _price_for_tier(tier: int, tier_1: int, tier_2: int, tier_3: int) -> int:
	if tier <= 1:
		return tier_1
	if tier == 2:
		return tier_2
	return tier_3
