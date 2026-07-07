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
