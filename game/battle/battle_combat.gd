class_name BattleCombat
extends Node

signal combat_started
signal buff_applied(source_id: int, target_id: int, stat: String, amount: int)
signal temporary_attack_applied(source_id: int, target_id: int, amount: int, result: int)
signal heal_applied(source_id: int, target_id: int, amount: int, result: int)
signal poison_applied(source_id: int, target_id: int, amount: int, result: int)
signal poison_damage_applied(target_id: int, amount: int, remaining_health: int)
signal death_prevented(card_id: int, effect_name: String, remaining_health: int)
signal attack_missed(attacker_id: int, target_id: int)
signal before_attack(attacker_id: int, target_id: int)
signal damage_applied(card_id: int, amount: int, remaining_health: int)
signal effect_damage_applied(source_id: int, target_id: int, amount: int, remaining_health: int)
signal card_died(card_id: int)
signal combat_won(winner_team: int)
signal combat_finished

@export_range(0.1, 5.0, 0.1) var cooldown_tick_seconds := 1.0
@export_range(0.1, 5.0, 0.1) var effect_seconds := 1.0

@onready var arena: BattleArena = get_parent() as BattleArena
@onready var buff_effect: BattleBuffEffect = $"../EffectsLayer/BuffEffect"
@onready var block_effect: BattleBlockEffect = $"../EffectsLayer/BlockEffect"
@onready var stat_popup: StatPopup = $"../UILayer/StatPopup"
@onready var effect_popup: EffectPopup = $"../UILayer/EffectPopup"

var _running := false
var _bindings_by_id: Dictionary = {}
var _last_winner_team := -1
var _run_token := 0


func start_combat(battle_seed: int = 0, snapshot: BattleBoardSnapshot = null, favored_team: int = CardSlot.TEAM_PLAYER) -> bool:
	if _running:
		return false
	_run_combat(battle_seed, snapshot, favored_team)
	return true


func get_board_snapshot() -> BattleBoardSnapshot:
	return BattleBoardSnapshot.from_arena(arena)


func is_running() -> bool:
	return _running


func force_stop() -> void:
	_run_token += 1
	for binding_value in _bindings_by_id.values():
		var binding: BattleCardBinding = binding_value as BattleCardBinding
		if binding and is_instance_valid(binding.visual):
			binding.visual.set_interaction_blocked(false)
	_bindings_by_id.clear()
	_running = false


func _run_combat(battle_seed: int, snapshot: BattleBoardSnapshot, favored_team: int) -> void:
	_run_token += 1
	var token: int = _run_token
	_running = true
	var active_snapshot: BattleBoardSnapshot = snapshot if snapshot else get_board_snapshot()
	var states: Array[BattleCardState] = _build_battle_states(active_snapshot)
	var events: Array[BattleEvent] = BattleSimulator.new().run(states, battle_seed, favored_team)
	_last_winner_team = _get_winner_team(states)
	for event in events:
		if token != _run_token:
			return
		await _play_event(event)
	if token != _run_token:
		return
	_finish_combat()


func _build_battle_states(snapshot: BattleBoardSnapshot) -> Array[BattleCardState]:
	_bindings_by_id.clear()
	var states := snapshot.to_states()
	for state in states:
		var slot := _find_slot(state.team, state.slot_index)
		if not slot:
			continue
		var card := slot.get_card()
		if not card or not card.card_data:
			continue
		_bindings_by_id[state.card_id] = BattleCardBinding.new(card, slot)
		card.reset_combat_visuals()
		if not card.stat_changed.is_connected(_on_stat_changed):
			card.stat_changed.connect(_on_stat_changed)
		card.set_interaction_blocked(true, true)
	return states


func _find_slot(team: int, slot_index: int) -> CardSlot:
	for slot in arena.get_all_slots():
		if slot.team == team and slot.slot_index == slot_index:
			return slot
	return null


func _play_event(event: BattleEvent) -> void:
	match event.type:
		BattleEvent.COMBAT_STARTED:
			combat_started.emit()
		BattleEvent.TICK:
			await _play_tick(event)
		BattleEvent.COOLDOWN_RESET:
			_play_cooldown_reset(event)
		BattleEvent.BUFF_APPLIED:
			await _play_buff(event)
		BattleEvent.TRAIT_APPLIED:
			await _play_trait_applied(event)
		BattleEvent.TEMPORARY_ATTACK_APPLIED:
			await _play_temporary_attack(event)
		BattleEvent.BEFORE_ATTACK:
			await _play_before_attack(event)
		BattleEvent.ATTACK_MISSED:
			await _play_attack_missed(event)
		BattleEvent.DAMAGE_APPLIED:
			await _play_damage(event)
		BattleEvent.EFFECT_DAMAGE_GROUP:
			await _play_effect_damage_group(event)
		BattleEvent.EFFECT_TRIGGERED:
			await _play_effect_triggered(event)
		BattleEvent.DEATH_EFFECT_TRIGGERED:
			await _play_death_effect_triggered(event)
		BattleEvent.HEAL_APPLIED:
			await _play_heal(event)
		BattleEvent.POISON_APPLIED:
			await _play_poison_applied(event)
		BattleEvent.POISON_GROUP_APPLIED:
			await _play_poison_group_applied(event)
		BattleEvent.POISON_DAMAGE:
			await _play_poison_damage(event)
		BattleEvent.DEATH_PREVENTED:
			await _play_death_prevented(event)
		BattleEvent.CARD_DIED:
			await _play_death(event)


func _play_tick(event: BattleEvent) -> void:
	await get_tree().create_timer(cooldown_tick_seconds).timeout
	var cooldowns: Dictionary = event.get_dictionary("cooldowns")
	for card_id in cooldowns:
		var binding := _get_binding(int(card_id))
		if binding:
			binding.visual.set_cooldown_value(int(cooldowns[card_id]), false)


func _play_cooldown_reset(event: BattleEvent) -> void:
	var binding := _get_binding(event.get_int("card_id"))
	if binding:
		binding.visual.set_cooldown_value(event.get_int("cooldown"), false)


func _play_buff(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := event.get_int("source_id")
	var target_id := event.get_int("target_id")
	var source := _get_binding(source_id)
	var target := _get_binding(target_id)
	if not source or not target:
		return
	var amount := event.get_int("amount")
	var stat := event.get_string("stat", "attack")
	var stat_type := CardStat.Type.HEALTH if stat == "health" else CardStat.Type.ATTACK
	await buff_effect.play(source.visual, target.visual, stat_type, amount)
	if stat == "health":
		target.visual.set_health_value(event.get_int("result"))
	else:
		target.visual.set_attack_value(event.get_int("result"))
	buff_applied.emit(source_id, target_id, stat, amount)
	await _wait_for_effect_time(effect_start_ms)


func _play_trait_applied(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var target := _get_binding(event.get_int("target_id"))
	if not target:
		return
	target.visual.set_runtime_trait(
		event.get_string("trait_id"),
		event.get_string("trait_display_text", event.get_string("trait_name", "Trait")),
		event.get_string("trait_description"),
		event.get_color("effect_color", Color("de9e41"))
	)
	effect_popup.show_text(
		target.visual,
		"%s +%d" % [event.get_string("trait_name", "Trait"), event.get_int("amount")],
		event.get_color("effect_color", Color("de9e41"))
	)
	await _wait_for_effect_time(effect_start_ms)


func _play_temporary_attack(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := event.get_int("source_id")
	var target_id := event.get_int("target_id")
	var source := _get_binding(source_id)
	var target := _get_binding(target_id)
	if not source or not target:
		return
	var amount := event.get_int("amount")
	var result := event.get_int("result")
	effect_popup.show_text(
		target.visual,
		event.get_string("effect_name", "Temporary Damage"),
		event.get_color("effect_color", CardStat.TEMPORARY_ATTACK_COLOR)
	)
	await buff_effect.play(source.visual, target.visual, CardStat.Type.TEMPORARY_ATTACK, amount)
	target.visual.set_temporary_attack_value(result)
	temporary_attack_applied.emit(source_id, target_id, amount, result)
	await _wait_for_effect_time(effect_start_ms)


func _play_heal(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := event.get_int("source_id")
	var target_id := event.get_int("target_id")
	var source := _get_binding(source_id)
	var target := _get_binding(target_id)
	if not source or not target:
		return
	var amount := event.get_int("amount")
	var target_health := event.get_int("target_health")
	await buff_effect.play(source.visual, target.visual, CardStat.Type.HEALTH, amount)
	target.visual.set_health_value(target_health)
	heal_applied.emit(source_id, target_id, amount, target_health)
	await _wait_for_effect_time(effect_start_ms)


func _play_poison_applied(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := event.get_int("source_id")
	var target_id := event.get_int("target_id")
	var amount := event.get_int("amount")
	var result := event.get_int("result")
	var source := _get_binding(source_id)
	var target := _get_binding(target_id)
	if not source or not target:
		return
	effect_popup.show_text(target.visual, "Poisoned", CardStat.POISON_FEEDBACK_COLOR)
	await buff_effect.play(source.visual, target.visual, CardStat.Type.POISON, amount)
	target.visual.set_poison_value(result)
	poison_applied.emit(source_id, target_id, amount, result)
	await _wait_for_effect_time(effect_start_ms)


func _play_poison_group_applied(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := event.get_int("source_id")
	var source := _get_binding(source_id)
	if not source:
		return
	var hit_tweens: Array[Tween] = []
	var results: Dictionary = event.get_dictionary("results")
	var flash_color := event.get_color("flash_color", Color("b0e535"))
	var source_center: Vector2 = source.visual.get_card_center()
	for target_id in results:
		var target := _get_binding(int(target_id))
		if not target:
			continue
		effect_popup.show_text(target.visual, "Poisoned", CardStat.POISON_FEEDBACK_COLOR)
		target.visual.set_poison_value(int(results[target_id]))
		poison_applied.emit(source_id, int(target_id), event.get_int("amount"), int(results[target_id]))
		hit_tweens.append(target.visual.start_hit_animation(source_center, flash_color))
	if not hit_tweens.is_empty():
		var first_hit_tween: Tween = hit_tweens[0]
		if first_hit_tween and first_hit_tween.is_running():
			await first_hit_tween.finished
	if bool(event.get_value("source_dies_after_effect", false)):
		await source.visual.play_death_animation(_get_death_fly_direction(source))
	await _wait_for_effect_time(effect_start_ms)


func _play_poison_damage(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var target_id := event.get_int("target_id")
	var target := _get_binding(target_id)
	if not target:
		return
	var damage := event.get_int("damage")
	var target_health := event.get_int("target_health")
	await buff_effect.play_stat_to_stat(
		target.visual,
		CardStat.Type.POISON,
		CardStat.Type.HEALTH,
		damage
	)
	target.visual.set_health_value(target_health)
	target.visual.set_poison_value(event.get_int("poison_remaining"))
	damage_applied.emit(target_id, damage, target_health)
	poison_damage_applied.emit(target_id, damage, target_health)
	await _wait_for_effect_time(effect_start_ms)


func _play_death_prevented(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var card_id := event.get_int("card_id")
	var binding := _get_binding(card_id)
	if not binding:
		return
	var effect_name := event.get_string("effect_name")
	var target_health := event.get_int("target_health")
	effect_popup.show_text(binding.visual, effect_name, event.get_color("effect_color"))
	binding.visual.set_health_value(target_health)
	binding.visual.set_poison_value(event.get_int("poison_remaining"))
	death_prevented.emit(card_id, effect_name, target_health)
	await binding.visual.play_survival_animation()
	await _wait_for_effect_time(effect_start_ms)


func _on_stat_changed(card: CardVisual, stat_type: CardStat.Type, delta: int) -> void:
	stat_popup.show_change(card, stat_type, delta)


func _play_before_attack(event: BattleEvent) -> void:
	var attacker_id := event.get_int("attacker_id")
	var target_id := event.get_int("target_id")
	var attacker := _get_binding(attacker_id)
	var target := _get_binding(target_id)
	if not attacker or not target:
		return
	before_attack.emit(attacker_id, target_id)
	await attacker.visual.play_attack_to_impact(target.visual.get_card_center())
	attacker.visual.start_attack_return()


func _play_attack_missed(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var attacker_id := event.get_int("attacker_id")
	var target_id := event.get_int("target_id")
	var attacker := _get_binding(attacker_id)
	var target := _get_binding(target_id)
	if not attacker or not target:
		return
	var midpoint := float(BattleArena.TEAM_SIZE) * 0.5
	var dodge_direction := -1.0 if target.slot.slot_index < midpoint else 1.0
	effect_popup.show_text(
		target.visual,
		event.get_string("effect_name"),
		event.get_color("effect_color")
	)
	await target.visual.play_dodge_animation(dodge_direction)
	while is_instance_valid(attacker.visual) and attacker.visual.is_attack_returning():
		await get_tree().process_frame
	if is_instance_valid(attacker.visual):
		attacker.visual.set_temporary_attack_value(event.get_int("temporary_attack_remaining"))
		attacker.visual.set_cooldown_value(event.get_int("attacker_cooldown"), false)
	attack_missed.emit(attacker_id, target_id)
	await _wait_for_effect_time(effect_start_ms)


func _play_damage(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var attacker_id := event.get_int("attacker_id")
	var target_id := event.get_int("target_id")
	var attacker := _get_binding(attacker_id)
	var target := _get_binding(target_id)
	if not attacker or not target:
		return
	var damage := event.get_int("damage")
	var remaining_health := event.get_int("target_health")
	target.visual.set_health_value(remaining_health)
	damage_applied.emit(target_id, damage, remaining_health)
	var extra_hit_tweens: Array[Tween] = []
	var extra_hits: Array = event.get_array("extra_hits")
	var hit_origin := attacker.visual.get_card_center()
	var flash_color := event.get_color("flash_color", CardVisual.ORANGE_COLOR)
	if not event.get_string("effect_name").is_empty():
		effect_popup.show_text(target.visual, event.get_string("effect_name"), event.get_color("effect_color", flash_color))
	for hit_value in extra_hits:
		var hit: BattleEffectHit = hit_value as BattleEffectHit
		if not hit:
			continue
		var extra_target := _get_binding(hit.target_id)
		if not extra_target:
			continue
		extra_target.visual.set_health_value(hit.target_health)
		damage_applied.emit(hit.target_id, hit.damage, hit.target_health)
		effect_damage_applied.emit(attacker_id, hit.target_id, hit.damage, hit.target_health)
		if hit.damage <= 0:
			effect_popup.show_text(extra_target.visual, "Block")
			await block_effect.play(extra_target.visual)
		else:
			extra_hit_tweens.append(extra_target.visual.start_hit_animation(hit_origin, flash_color))
	if damage <= 0:
		effect_popup.show_text(target.visual, "Block")
		await block_effect.play(target.visual)
	else:
		var main_hit := target.visual.start_hit_animation(hit_origin, flash_color)
		if main_hit and main_hit.is_running():
			await main_hit.finished
	if not extra_hit_tweens.is_empty():
		var first_extra_hit: Tween = extra_hit_tweens[0]
		if first_extra_hit and first_extra_hit.is_running():
			await first_extra_hit.finished
	while is_instance_valid(attacker.visual) and attacker.visual.is_attack_returning():
		await get_tree().process_frame
	if is_instance_valid(attacker.visual):
		attacker.visual.set_temporary_attack_value(event.get_int("temporary_attack_remaining"))
		attacker.visual.set_cooldown_value(event.get_int("attacker_cooldown"), false)
	await _wait_for_effect_time(effect_start_ms)


func _play_effect_damage_group(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := event.get_int("source_id")
	var source := _get_binding(source_id)
	if not source:
		return
	var hit_tweens: Array[Tween] = []
	var hits: Array = event.get_array("hits")
	var flash_color := event.get_color("flash_color", CardVisual.ORANGE_COLOR)
	var source_center: Vector2 = source.visual.get_card_center()
	for hit_value in hits:
		var hit: BattleEffectHit = hit_value as BattleEffectHit
		if not hit:
			continue
		var target_id := hit.target_id
		var target := _get_binding(target_id)
		if not target:
			continue
		if not event.get_string("effect_name").is_empty():
			effect_popup.show_text(target.visual, event.get_string("effect_name"), event.get_color("effect_color", flash_color))
		var damage := hit.damage
		var remaining_health := hit.target_health
		target.visual.set_health_value(remaining_health)
		damage_applied.emit(target_id, damage, remaining_health)
		effect_damage_applied.emit(source_id, target_id, damage, remaining_health)
		hit_tweens.append(target.visual.start_hit_animation(source_center, flash_color))
	if not hit_tweens.is_empty():
		var first_hit_tween: Tween = hit_tweens[0]
		if first_hit_tween and first_hit_tween.is_running():
			await first_hit_tween.finished
	if bool(event.get_value("source_dies_after_effect", false)):
		await source.visual.play_death_animation(_get_death_fly_direction(source))
	await _wait_for_effect_time(effect_start_ms)


func _play_effect_triggered(event: BattleEvent) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var binding := _get_binding(event.get_int("card_id"))
	if not binding:
		return
	effect_popup.show_text(
		binding.visual,
		event.get_string("effect_name"),
		event.get_color("effect_color")
	)
	await _wait_for_effect_time(effect_start_ms)


func _play_death_effect_triggered(event: BattleEvent) -> void:
	var binding := _get_binding(event.get_int("card_id"))
	if not binding:
		return
	await binding.visual.play_death_effect_windup(event.get_color("effect_color", Color("6000ff")))


func _play_death(event: BattleEvent) -> void:
	var card_id := event.get_int("card_id")
	var binding := _get_binding(card_id)
	if not binding:
		return
	await binding.visual.play_death_animation(_get_death_fly_direction(binding))
	binding.slot.release(binding.visual)
	binding.visual.queue_free()
	_bindings_by_id.erase(card_id)
	card_died.emit(card_id)


func _get_death_fly_direction(binding: BattleCardBinding) -> Vector2:
	return Vector2.UP if binding.slot.team == CardSlot.TEAM_ENEMY else Vector2.DOWN


func _get_binding(card_id: int) -> BattleCardBinding:
	var binding := _bindings_by_id.get(card_id) as BattleCardBinding
	if binding and is_instance_valid(binding.visual):
		return binding
	return null


func _wait_for_effect_time(start_ms: int) -> void:
	var elapsed_seconds := float(Time.get_ticks_msec() - start_ms) / 1000.0
	var remaining_seconds := effect_seconds - elapsed_seconds
	if remaining_seconds > 0.0:
		await get_tree().create_timer(remaining_seconds).timeout


func _finish_combat() -> void:
	for binding_value in _bindings_by_id.values():
		var binding := binding_value as BattleCardBinding
		if binding and is_instance_valid(binding.visual):
			binding.visual.set_interaction_blocked(false)
	_bindings_by_id.clear()
	_running = false
	if _last_winner_team >= 0:
		combat_won.emit(_last_winner_team)
	combat_finished.emit()


func _get_winner_team(states: Array[BattleCardState]) -> int:
	var player_alive := false
	var enemy_alive := false
	for state in states:
		if not state.is_alive():
			continue
		if state.team == CardSlot.TEAM_PLAYER:
			player_alive = true
		elif state.team == CardSlot.TEAM_ENEMY:
			enemy_alive = true
	if player_alive and not enemy_alive:
		return CardSlot.TEAM_PLAYER
	if enemy_alive and not player_alive:
		return CardSlot.TEAM_ENEMY
	return -1
