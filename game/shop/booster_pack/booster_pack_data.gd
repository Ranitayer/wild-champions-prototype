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

@export_group("Soft Pity")
@export var soft_pity_enabled := true
@export_range(0.0, 100.0, 0.1) var rare_pity_per_miss := 1.0
@export_range(0.0, 100.0, 0.1) var epic_pity_per_miss := 0.25
@export_range(0.0, 100.0, 0.01) var mythic_pity_per_miss := 0.05
@export_range(0.0, 100.0, 0.1) var rare_pity_max := 20.0
@export_range(0.0, 100.0, 0.1) var epic_pity_max := 5.0
@export_range(0.0, 100.0, 0.1) var mythic_pity_max := 1.0

func pick_rewards(count: int, random: RandomNumberGenerator, pity_misses := 0) -> Array[CardData]:
	var rewards: Array[CardData] = []
	if not random:
		push_error("BoosterPackData needs seeded RandomNumberGenerator.")
		return rewards
	var picked: Dictionary = {}
	var cards: Array[Resource] = _get_cards()
	var attempts: int = maxi(count * 30, 30)

	while rewards.size() < count and attempts > 0:
		attempts -= 1
		var rarity: CardData.Rarity = _roll_rarity(random, pity_misses)
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


func has_high_rarity(cards: Array[CardData]) -> bool:
	for card in cards:
		if card and card.rarity >= CardData.Rarity.RARE:
			return true
	return false


func get_pack_key() -> String:
	if not resource_path.is_empty():
		return resource_path
	return title


func get_effective_chances(pity_misses: int) -> Array[float]:
	return _get_effective_chances(pity_misses)


func _roll_rarity(random: RandomNumberGenerator, pity_misses := 0) -> CardData.Rarity:
	var chances := _get_effective_chances(pity_misses)
	var common: float = chances[CardData.Rarity.COMMON]
	var uncommon: float = chances[CardData.Rarity.UNCOMMON]
	var rare: float = chances[CardData.Rarity.RARE]
	var epic: float = chances[CardData.Rarity.EPIC]
	var mythic: float = chances[CardData.Rarity.MYTHIC]
	var total_chance: float = common + uncommon + rare + epic + mythic
	if total_chance <= 0.0:
		return CardData.Rarity.COMMON

	var roll: float = random.randf() * total_chance
	if roll < common:
		return CardData.Rarity.COMMON
	roll -= common
	if roll < uncommon:
		return CardData.Rarity.UNCOMMON
	roll -= uncommon
	if roll < rare:
		return CardData.Rarity.RARE
	roll -= rare
	if roll < epic:
		return CardData.Rarity.EPIC
	return CardData.Rarity.MYTHIC


func _get_effective_chances(pity_misses: int) -> Array[float]:
	var chances: Array[float] = [
		common_chance,
		uncommon_chance,
		rare_chance,
		epic_chance,
		mythic_chance,
	]
	if not soft_pity_enabled or pity_misses <= 0:
		return chances

	var rare_bonus: float = maxf(0.0, minf(rare_chance + rare_pity_per_miss * pity_misses, rare_pity_max) - rare_chance)
	var epic_bonus: float = maxf(0.0, minf(epic_chance + epic_pity_per_miss * pity_misses, epic_pity_max) - epic_chance)
	var mythic_bonus: float = maxf(0.0, minf(mythic_chance + mythic_pity_per_miss * pity_misses, mythic_pity_max) - mythic_chance)
	var total_bonus := rare_bonus + epic_bonus + mythic_bonus
	var common_loss: float = minf(chances[CardData.Rarity.COMMON], total_bonus)
	chances[CardData.Rarity.COMMON] -= common_loss
	total_bonus -= common_loss
	if total_bonus > 0.0:
		chances[CardData.Rarity.UNCOMMON] = maxf(0.0, chances[CardData.Rarity.UNCOMMON] - total_bonus)
	chances[CardData.Rarity.RARE] += rare_bonus
	chances[CardData.Rarity.EPIC] += epic_bonus
	chances[CardData.Rarity.MYTHIC] += mythic_bonus
	return chances


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
