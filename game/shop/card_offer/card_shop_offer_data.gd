class_name CardShopOfferData
extends BoosterPackData

@export_group("Rarity Prices")
@export_range(0, 999, 1) var common_price := 3
@export_range(0, 999, 1) var uncommon_price := 8
@export_range(0, 999, 1) var rare_price := 12
@export_range(0, 999, 1) var epic_price := 25
@export_range(0, 999, 1) var mythic_price := 40


func get_price(rarity: int) -> int:
	match rarity:
		CardData.Rarity.UNCOMMON:
			return uncommon_price
		CardData.Rarity.RARE:
			return rare_price
		CardData.Rarity.EPIC:
			return epic_price
		CardData.Rarity.MYTHIC:
			return mythic_price
		_:
			return common_price
