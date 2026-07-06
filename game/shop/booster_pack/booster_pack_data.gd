class_name BoosterPackData
extends Resource

@export var card_catalog: Resource
@export_range(0, 999, 1) var price := 5
@export_range(1, 10, 1) var reward_count := 3
@export var title := "Wild Booster Pack"
@export_multiline var description := "Choose 1 of 3 cards for your collection."

@export_group("Visuals")
@export var pack_color := Color("de9e41")
@export var accent_color := Color("884b2b")

@export_group("Rarity Odds")
@export_range(0.0, 100.0, 0.1) var common_chance := 70.0
@export_range(0.0, 100.0, 0.1) var uncommon_chance := 20.0
@export_range(0.0, 100.0, 0.1) var rare_chance := 8.0
@export_range(0.0, 100.0, 0.1) var epic_chance := 1.8
@export_range(0.0, 100.0, 0.1) var mythic_chance := 0.2


func pick_rewards(count: int, random: RandomNumberGenerator) -> Array[CardData]:
	var rewards: Array[CardData] = []
	if not random:
		push_error("BoosterPackData needs seeded RandomNumberGenerator.")
		return rewards
	var picked: Dictionary = {}
	var cards: Array[Resource] = _get_cards()
	var attempts: int = maxi(count * 30, 30)

	while rewards.size() < count and attempts > 0:
		attempts -= 1
		var rarity: CardData.Rarity = _roll_rarity(random)
		var card: CardData = _pick_unused_card(rarity, picked, cards, random)
		if not card:
			continue
		rewards.append(card)
		picked[_card_key(card)] = true

	if rewards.size() < count:
		for card in _get_unused_cards(picked, cards, random):
			rewards.append(card)
			if rewards.size() >= count:
				break

	return rewards


func _roll_rarity(random: RandomNumberGenerator) -> CardData.Rarity:
	var total_chance: float = common_chance + uncommon_chance + rare_chance + epic_chance + mythic_chance
	if total_chance <= 0.0:
		return CardData.Rarity.COMMON

	var roll: float = random.randf() * total_chance
	if roll < common_chance:
		return CardData.Rarity.COMMON
	roll -= common_chance
	if roll < uncommon_chance:
		return CardData.Rarity.UNCOMMON
	roll -= uncommon_chance
	if roll < rare_chance:
		return CardData.Rarity.RARE
	roll -= rare_chance
	if roll < epic_chance:
		return CardData.Rarity.EPIC
	return CardData.Rarity.MYTHIC


func _pick_unused_card(
	rarity: CardData.Rarity,
	picked: Dictionary,
	cards: Array[Resource],
	random: RandomNumberGenerator
) -> CardData:
	var bucket: Array[CardData] = []
	for resource in cards:
		var card: CardData = resource as CardData
		if card and card.rarity == rarity and not picked.has(_card_key(card)):
			bucket.append(card)

	if bucket.is_empty():
		return null

	var index: int = random.randi_range(0, bucket.size() - 1)
	return bucket[index]


func _get_unused_cards(
	picked: Dictionary,
	cards: Array[Resource],
	random: RandomNumberGenerator
) -> Array[CardData]:
	var unused: Array[CardData] = []
	for resource in cards:
		var card: CardData = resource as CardData
		if card and not picked.has(_card_key(card)):
			unused.append(card)
	_shuffle_cards(unused, random)
	return unused


func _shuffle_cards(cards: Array[CardData], random: RandomNumberGenerator) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_index: int = random.randi_range(0, index)
		var card: CardData = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = card


func _get_cards() -> Array[Resource]:
	var catalog: CardCatalog = card_catalog as CardCatalog
	if catalog:
		return catalog.cards
	return []


func _card_key(card: CardData) -> String:
	if not card.resource_path.is_empty():
		return card.resource_path
	return card.title


func format_chance(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


func get_rarity_chance(rarity: int) -> float:
	match rarity:
		CardData.Rarity.UNCOMMON:
			return uncommon_chance
		CardData.Rarity.RARE:
			return rare_chance
		CardData.Rarity.EPIC:
			return epic_chance
		CardData.Rarity.MYTHIC:
			return mythic_chance
		_:
			return common_chance
