class_name CardStat
extends RefCounted

enum Type {
	ATTACK,
	HEALTH,
	COOLDOWN,
	POISON,
	TEMPORARY_ATTACK,
}

const ATTACK_COLOR := Color("4f8fba")
const HEALTH_COLOR := Color("a53030")
const COOLDOWN_COLOR := Color("151d28")
const POISON_COLOR := Color("468232")
const POISON_FEEDBACK_COLOR := Color("70e926")
const TEMPORARY_ATTACK_COLOR := Color("253a5e")


static func color(stat_type: Type) -> Color:
	match stat_type:
		Type.HEALTH:
			return HEALTH_COLOR
		Type.COOLDOWN:
			return COOLDOWN_COLOR
		Type.POISON:
			return POISON_COLOR
		Type.TEMPORARY_ATTACK:
			return TEMPORARY_ATTACK_COLOR
		_:
			return ATTACK_COLOR
