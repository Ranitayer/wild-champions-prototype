class_name BattleSimulator
extends RefCounted

const MAX_TICKS := 1000
const MISS_STALEMATE_MULTIPLIER := 8
const TEAM_ENEMY := 0
const TEAM_PLAYER := 1

var _rng := RandomNumberGenerator.new()


func run(cards: Array[BattleCardState], battle_seed: int = 0) -> Array[Dictionary]:
	var resolved_seed: int = battle_seed if battle_seed != 0 else _derive_seed(cards)
	_rng.seed = resolved_seed
	var events: Array[Dictionary] = [{"type": "combat_started", "seed": resolved_seed}]
	_apply_start_of_combat_effects(cards, events)
	var tick_count := 0
	var stalled_ticks := 0
	var previous_progress := _progress_signature(cards)
	while _team_alive(cards, TEAM_PLAYER) and _team_alive(cards, TEAM_ENEMY):
		tick_count += 1
		if tick_count > MAX_TICKS:
			break
		var cooldowns: Dictionary = {}
		var player_ready: Array[BattleCardState] = []
		var enemy_ready: Array[BattleCardState] = []
		for card in _ordered_cards(cards):
			card.cooldown -= 1
			cooldowns[card.card_id] = card.cooldown
			if card.cooldown <= 0:
				if card.team == TEAM_PLAYER:
					player_ready.append(card)
				else:
					enemy_ready.append(card)
		events.append({"type": "tick", "cooldowns": cooldowns})

		_resolve_ready_cards(player_ready, enemy_ready, cards, events)
		var current_progress := _progress_signature(cards)
		if current_progress == previous_progress:
			stalled_ticks += 1
		else:
			stalled_ticks = 0
			previous_progress = current_progress
		if stalled_ticks >= _stalemate_window(cards):
			break
	return events


func _resolve_ready_cards(
	player_ready: Array[BattleCardState],
	enemy_ready: Array[BattleCardState],
	cards: Array[BattleCardState],
	events: Array[Dictionary]
) -> void:
	var player_index := 0
	var enemy_index := 0
	while player_index < player_ready.size() or enemy_index < enemy_ready.size():
		while player_index < player_ready.size() and not player_ready[player_index].is_alive():
			player_index += 1
		if player_index < player_ready.size():
			_resolve_attack(player_ready[player_index], cards, events)
			player_index += 1

		while enemy_index < enemy_ready.size() and not enemy_ready[enemy_index].is_alive():
			enemy_index += 1
		if enemy_index < enemy_ready.size():
			_resolve_attack(enemy_ready[enemy_index], cards, events)
			enemy_index += 1


func _resolve_attack(attacker: BattleCardState, cards: Array[BattleCardState], events: Array[Dictionary]) -> void:
	if not attacker.is_alive():
		return
	var target := _find_target(attacker, cards)
	if not target:
		return
	attacker.attacks_made += 1
	_apply_before_attack_effects(attacker, target, cards, events)
	events.append({
		"type": "before_attack",
		"attacker_id": attacker.card_id,
		"target_id": target.card_id,
	})
	var miss_trait := target.get_attack_miss_trait()
	if miss_trait:
		var miss_chance := miss_trait.definition.get_incoming_attack_miss_chance(miss_trait.value)
		if _rng.randf() < miss_chance:
			attacker.cooldown = maxi(1, attacker.data.cooldown)
			var miss_temporary_attack_remaining := attacker.consume_temporary_attack()
			events.append({
				"type": "attack_missed",
				"attacker_id": attacker.card_id,
				"target_id": target.card_id,
				"effect_name": "Missed",
				"effect_color": miss_trait.definition.get_trigger_color_hex(),
				"attacker_cooldown": attacker.cooldown,
				"temporary_attack_remaining": miss_temporary_attack_remaining,
			})
			return
	var triggering_poison := target.poison
	var target_health_before := target.health
	var damage := target.modify_incoming_attack_damage(attacker.get_total_attack())
	target.health -= damage
	attacker.cooldown = maxi(1, attacker.data.cooldown)
	var temporary_attack_remaining := attacker.consume_temporary_attack()
	events.append({
		"type": "damage_applied",
		"attacker_id": attacker.card_id,
		"target_id": target.card_id,
		"damage": damage,
		"target_health": target.health,
		"attacker_cooldown": attacker.cooldown,
		"temporary_attack_remaining": temporary_attack_remaining,
	})
	_apply_death_prevention(target, events)
	var overflow_damage := attacker.get_attack_overflow_damage(
		damage,
		target_health_before,
		target.is_alive()
	)
	if overflow_damage > 0 and _has_living_adjacent(target, cards):
		var overflow_trait := attacker.get_attack_overflow_trait(
			damage,
			target_health_before,
			target.is_alive()
		)
		if overflow_trait:
			events.append({
				"type": "effect_triggered",
				"card_id": attacker.card_id,
				"effect_name": overflow_trait.definition.display_name,
				"effect_color": overflow_trait.definition.get_trigger_color_hex(),
			})
		_apply_overflow_damage(attacker, target, overflow_damage, cards, events)
	if target.is_alive() and triggering_poison > 0 and target.poison > 0:
		var poison_damage := mini(triggering_poison, target.poison)
		target.health -= poison_damage
		target.poison -= 1
		events.append({
			"type": "poison_damage",
			"target_id": target.card_id,
			"damage": poison_damage,
			"target_health": target.health,
			"poison_remaining": target.poison,
		})
		_apply_death_prevention(target, events)
	if target.is_alive():
		var poison_amount := attacker.get_outgoing_poison_amount()
		if poison_amount > 0:
			target.poison += poison_amount
			events.append({
				"type": "poison_applied",
				"source_id": attacker.card_id,
				"target_id": target.card_id,
				"amount": poison_amount,
				"result": target.poison,
			})
	var heal_amount := attacker.get_attack_heal_amount(damage)
	if heal_amount > 0:
		attacker.heal(heal_amount)
		events.append({
			"type": "heal_applied",
			"source_id": target.card_id,
			"target_id": attacker.card_id,
			"amount": heal_amount,
			"target_health": attacker.health,
		})
	if not target.is_alive():
		events.append({"type": "card_died", "card_id": target.card_id})


func _apply_death_prevention(card: BattleCardState, events: Array[Dictionary]) -> void:
	var trait_state := card.try_prevent_death()
	if not trait_state:
		return
	events.append({
		"type": "death_prevented",
		"card_id": card.card_id,
		"effect_name": trait_state.definition.display_name,
		"effect_color": trait_state.definition.get_trigger_color_hex(),
		"target_health": card.health,
		"poison_remaining": card.poison,
	})


func _apply_overflow_damage(
	source: BattleCardState,
	defeated_target: BattleCardState,
	amount: int,
	cards: Array[BattleCardState],
	events: Array[Dictionary]
) -> void:
	var left_target := _find_living_card_at(
		cards,
		defeated_target.team,
		defeated_target.slot_index - 1
	)
	var right_target := _find_living_card_at(
		cards,
		defeated_target.team,
		defeated_target.slot_index + 1
	)
	var targets: Array[BattleCardState] = []
	var damage_amounts: Array[int] = []
	if left_target and right_target:
		targets.assign([left_target, right_target])
		damage_amounts.assign([ceili(amount * 0.5), floori(amount * 0.5)])
	elif left_target:
		targets.append(left_target)
		damage_amounts.append(amount)
	elif right_target:
		targets.append(right_target)
		damage_amounts.append(amount)
	_deal_grouped_effect_damage(source, targets, damage_amounts, events)


func _has_living_adjacent(target: BattleCardState, cards: Array[BattleCardState]) -> bool:
	return (
		_find_living_card_at(cards, target.team, target.slot_index - 1) != null
		or _find_living_card_at(cards, target.team, target.slot_index + 1) != null
	)


func _deal_grouped_effect_damage(
	source: BattleCardState,
	targets: Array[BattleCardState],
	damage_amounts: Array[int],
	events: Array[Dictionary]
) -> void:
	var hits: Array[Dictionary] = []
	for index in targets.size():
		var amount := damage_amounts[index]
		if amount <= 0:
			continue
		var target := targets[index]
		target.health -= amount
		hits.append({
			"target_id": target.card_id,
			"damage": amount,
			"target_health": target.health,
		})
	if hits.is_empty():
		return
	events.append({
		"type": "effect_damage_group",
		"source_id": source.card_id,
		"hits": hits,
	})
	for target in targets:
		_apply_death_prevention(target, events)
		if not target.is_alive():
			events.append({"type": "card_died", "card_id": target.card_id})


func _find_living_card_at(
	cards: Array[BattleCardState],
	team: int,
	slot_index: int
) -> BattleCardState:
	for card in cards:
		if card.team == team and card.slot_index == slot_index and card.is_alive():
			return card
	return null


func _apply_start_of_combat_effects(cards: Array[BattleCardState], events: Array[Dictionary]) -> void:
	for source in _ordered_cards(cards):
		for effect_resource in source.get_effects():
			var effect := effect_resource as CardEffect
			if effect:
				effect.apply_start_of_combat(source, cards, events)


func _apply_before_attack_effects(
	source: BattleCardState,
	target: BattleCardState,
	cards: Array[BattleCardState],
	events: Array[Dictionary]
) -> void:
	for effect_resource in source.get_effects():
		var effect := effect_resource as CardEffect
		if effect:
			effect.apply_before_attack(source, target, cards, events)


func _find_target(attacker: BattleCardState, cards: Array[BattleCardState]) -> BattleCardState:
	var enemies: Array[BattleCardState] = []
	for card in cards:
		if card.team != attacker.team and card.is_alive():
			enemies.append(card)
	for index in _target_index_order(attacker.slot_index, _board_slot_count(cards)):
		for enemy in enemies:
			if enemy.slot_index == index:
				return enemy
	return null


func _ordered_cards(cards: Array[BattleCardState]) -> Array[BattleCardState]:
	var ordered: Array[BattleCardState] = []
	var slot_count := _board_slot_count(cards)
	for index in range(slot_count):
		_append_card_at(ordered, cards, TEAM_PLAYER, index)
		_append_card_at(ordered, cards, TEAM_ENEMY, index)
	return ordered


func _append_card_at(result: Array[BattleCardState], cards: Array[BattleCardState], team: int, index: int) -> void:
	for card in cards:
		if card.team == team and card.slot_index == index and card.is_alive():
			result.append(card)
			return


func _target_index_order(center_index: int, slot_count: int) -> Array[int]:
	var order: Array[int] = []
	for distance in range(slot_count):
		var left_index := center_index - distance
		var right_index := center_index + distance
		if left_index >= 0:
			order.append(left_index)
		if distance > 0 and right_index < slot_count:
			order.append(right_index)
	return order


func _board_slot_count(cards: Array[BattleCardState]) -> int:
	var count := 0
	for card in cards:
		count = maxi(count, card.slot_index + 1)
	return count


func _team_alive(cards: Array[BattleCardState], team: int) -> bool:
	for card in cards:
		if card.team == team and card.is_alive():
			return true
	return false


func _progress_signature(cards: Array[BattleCardState]) -> String:
	var values := PackedStringArray()
	for card in cards:
		values.append(card.get_stalemate_signature())
	return "|".join(values)


func _derive_seed(cards: Array[BattleCardState]) -> int:
	var result := 5381
	for card in _ordered_cards(cards):
		for byte in card.data.title.to_utf8_buffer():
			result = _mix_seed(result, byte)
		for value in [card.team, card.slot_index, card.tier, card.attack, card.health, card.cooldown]:
			result = _mix_seed(result, int(value))
		for trait_state in card.traits:
			for byte in str(trait_state.definition.trait_id).to_utf8_buffer():
				result = _mix_seed(result, byte)
			result = _mix_seed(result, trait_state.value)
	return maxi(1, result)


func _mix_seed(current: int, value: int) -> int:
	return (current * 33 + value) % 2147483647


func _stalemate_window(cards: Array[BattleCardState]) -> int:
	var ticks := 1
	var multiplier := 1
	for card in cards:
		if card.is_alive():
			ticks = maxi(ticks, maxi(1, maxi(card.data.cooldown, card.cooldown)))
			if card.get_attack_miss_trait():
				multiplier = MISS_STALEMATE_MULTIPLIER
			for effect_resource in card.get_effects():
				var effect := effect_resource as CardEffect
				if effect:
					multiplier = maxi(multiplier, effect.get_attack_cycle_length())
	return ticks * multiplier
