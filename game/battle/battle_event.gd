class_name BattleEvent
extends RefCounted

const COMBAT_STARTED := "combat_started"
const TICK := "tick"
const BUFF_APPLIED := "buff_applied"
const TEMPORARY_ATTACK_APPLIED := "temporary_attack_applied"
const BEFORE_ATTACK := "before_attack"
const ATTACK_MISSED := "attack_missed"
const DAMAGE_APPLIED := "damage_applied"
const EFFECT_DAMAGE_GROUP := "effect_damage_group"
const EFFECT_TRIGGERED := "effect_triggered"
const DEATH_EFFECT_TRIGGERED := "death_effect_triggered"
const HEAL_APPLIED := "heal_applied"
const POISON_APPLIED := "poison_applied"
const POISON_DAMAGE := "poison_damage"
const DEATH_PREVENTED := "death_prevented"
const CARD_DIED := "card_died"

var type := ""
var data: Dictionary = {}


func _init(event_type: String = "", event_data: Dictionary = {}) -> void:
	type = event_type
	data = event_data


static func add(events: Array[BattleEvent], event_type: String, event_data: Dictionary = {}) -> void:
	events.append(BattleEvent.new(event_type, event_data))


func get_value(key: String, default_value: Variant = null) -> Variant:
	return data.get(key, default_value)


func get_int(key: String, default_value: int = 0) -> int:
	return int(data.get(key, default_value))


func get_string(key: String, default_value: String = "") -> String:
	return str(data.get(key, default_value))


func get_color(key: String, default_value: Color = Color.WHITE) -> Color:
	var value: Variant = data.get(key, default_value)
	if value is Color:
		return value
	return Color(str(value))


func get_dictionary(key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	if value is Dictionary:
		return value
	return {}


func get_array(key: String) -> Array:
	var value: Variant = data.get(key, [])
	if value is Array:
		return value
	return []
