class_name BattleTraitState
extends RefCounted

var definition: CardTrait
var value: int
var triggered := false


func _init(trait_definition: CardTrait, trait_value: int) -> void:
	definition = trait_definition
	value = clampi(trait_value, 1, definition.get_max_value())


func add(amount: int) -> void:
	value = clampi(value + amount, 1, definition.get_max_value())
