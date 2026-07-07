class_name BattleEffectHit
extends RefCounted

var target_id := 0
var damage := 0
var target_health := 0


func _init(hit_target_id: int = 0, hit_damage: int = 0, hit_target_health: int = 0) -> void:
	target_id = hit_target_id
	damage = hit_damage
	target_health = hit_target_health
