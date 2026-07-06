class_name BattleCardState
extends RefCounted

var card_id: int
var data: CardData
var team: int
var slot_index: int
var tier: int
var attack: int
var health: int
var cooldown: int
var poison: int
var attacks_made: int
var traits: Array[BattleTraitState] = []
var temporary_attacks: Array[BattleTemporaryAttack] = []


func _init(id: int, card_data: CardData, card_team: int, index: int, card_tier := 1) -> void:
	card_id = id
	data = card_data
	team = card_team
	slot_index = index
	tier = clampi(card_tier, 1, data.get_max_tier())
	attack = data.get_attack(tier)
	health = data.get_health(tier)
	cooldown = maxi(1, data.cooldown)
	poison = 0
	attacks_made = 0
	for trait_resource in data.get_traits(tier):
		var trait_definition := trait_resource as CardTrait
		if trait_definition:
			acquire_trait(trait_definition, trait_definition.value)


func is_alive() -> bool:
	return health > 0


func get_effects() -> Array[Resource]:
	return data.get_effects(tier)


func acquire_trait(definition: CardTrait, amount := 1) -> void:
	for trait_state in traits:
		if trait_state.definition.trait_id == definition.trait_id:
			trait_state.add(amount)
			return
	traits.append(BattleTraitState.new(definition, amount))


func modify_incoming_attack_damage(damage: int) -> int:
	var result := damage
	for trait_state in traits:
		result = trait_state.definition.modify_incoming_attack_damage(result, trait_state.value)
	return maxi(0, result)


func get_attack_heal_amount(damage_done: int) -> int:
	var result := 0
	for trait_state in traits:
		result += trait_state.definition.get_attack_heal_amount(damage_done, trait_state.value)
	return maxi(0, result)


func get_outgoing_poison_amount() -> int:
	var result := 0
	for trait_state in traits:
		result += trait_state.definition.get_outgoing_poison_amount(trait_state.value)
	return maxi(0, result)


func get_total_attack() -> int:
	return attack + get_temporary_attack()


func add_permanent_attack(amount: int) -> int:
	attack += amount
	return attack


func get_temporary_attack() -> int:
	var result := 0
	for modifier in temporary_attacks:
		result += modifier.amount
	return result


func add_temporary_attack(amount: int, attack_uses := 1) -> int:
	if amount > 0:
		temporary_attacks.append(BattleTemporaryAttack.new(amount, attack_uses))
	return get_temporary_attack()


func consume_temporary_attack() -> int:
	for index in range(temporary_attacks.size() - 1, -1, -1):
		if temporary_attacks[index].consume_attack():
			temporary_attacks.remove_at(index)
	return get_temporary_attack()


func get_attack_miss_trait() -> BattleTraitState:
	for trait_state in traits:
		if trait_state.definition.get_incoming_attack_miss_chance(trait_state.value) > 0.0:
			return trait_state
	return null


func get_attack_overflow_damage(damage: int, target_health_before: int, target_survived: bool) -> int:
	var result := 0
	for trait_state in traits:
		result += trait_state.definition.get_attack_overflow_damage(
			damage,
			target_health_before,
			target_survived,
			trait_state.value
		)
	return maxi(0, result)


func get_attack_overflow_trait(
	damage: int,
	target_health_before: int,
	target_survived: bool
) -> BattleTraitState:
	for trait_state in traits:
		if trait_state.definition.get_attack_overflow_damage(
			damage,
			target_health_before,
			target_survived,
			trait_state.value
		) > 0:
			return trait_state
	return null


func try_prevent_death() -> BattleTraitState:
	if is_alive():
		return null
	for trait_state in traits:
		if trait_state.triggered:
			continue
		var survival_health := trait_state.definition.get_lethal_survival_health(trait_state.value)
		if survival_health <= 0:
			continue
		trait_state.triggered = true
		health = survival_health
		if trait_state.definition.clears_negative_effects_on_survival():
			clear_negative_effects()
		return trait_state
	return null


func clear_negative_effects() -> void:
	poison = 0
	var active_traits: Array[BattleTraitState] = []
	for trait_state in traits:
		if not trait_state.definition.is_negative_effect:
			active_traits.append(trait_state)
	traits = active_traits


func heal(amount: int) -> void:
	health += maxi(0, amount)


func get_stalemate_signature() -> String:
	var values := PackedStringArray([
		str(card_id),
		str(team),
		str(slot_index),
		str(tier),
		str(attack),
		str(health),
		str(poison),
	])
	for modifier in temporary_attacks:
		values.append("temporary_attack:%d:%d" % [modifier.amount, modifier.attacks_remaining])
	for trait_state in traits:
		values.append("%s:%d:%d" % [
			trait_state.definition.trait_id,
			trait_state.value,
			int(trait_state.triggered),
		])
	return ":".join(values)
