class_name ShopRandom
extends Node

@export var random_seed := 1

var generator := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group("shop_random")
	set_seed(random_seed)


func set_seed(shop_seed: int) -> void:
	random_seed = maxi(1, shop_seed)
	generator.seed = random_seed
