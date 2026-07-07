class_name ShopRandom
extends Node

@export var random_seed := 1

var generator := RandomNumberGenerator.new()
var _pity_misses_by_pack: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("shop_random")
	set_seed(random_seed)


func set_seed(shop_seed: int) -> void:
	random_seed = maxi(1, shop_seed)
	generator.seed = random_seed


func pick_booster_rewards(data: BoosterPackData, count: int) -> Array[CardData]:
	if not data:
		return []
	var pack_key := data.get_pack_key()
	var pity_misses := int(_pity_misses_by_pack.get(pack_key, 0))
	var rewards := data.pick_rewards(count, generator, pity_misses)
	_update_pity(data, rewards)
	return rewards


func _update_pity(data: BoosterPackData, rewards: Array[CardData]) -> void:
	var pack_key := data.get_pack_key()
	if data.has_high_rarity(rewards):
		_pity_misses_by_pack[pack_key] = 0
	else:
		_pity_misses_by_pack[pack_key] = int(_pity_misses_by_pack.get(pack_key, 0)) + 1
