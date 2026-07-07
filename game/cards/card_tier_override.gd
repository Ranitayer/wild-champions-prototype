@tool
class_name CardTierOverride
extends Resource

@export_range(2, 3, 1) var tier := 2
@export_range(0, 999, 1) var attack := 0
@export_range(0, 999, 1) var health := 0
@export_multiline var description := ""
@export var replace_effects := false
@export var effects: Array[Resource] = []
@export var replace_traits := false
@export var traits: Array[Resource] = []
