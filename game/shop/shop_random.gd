class_name ShopRandom
extends Node

@export var random_seed := 1

var generator := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group("shop_random")
	generator.seed = random_seed
