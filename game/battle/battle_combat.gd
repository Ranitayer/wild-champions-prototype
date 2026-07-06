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


func start_combat() -> bool:
	if _running:
		return false
	_run_combat()
	return true


func is_running() -> bool:
	return _running


func _run_combat() -> void:
	_running = true
	var states := _build_battle_states()
	var events := BattleSimulator.new().run(states)
	for event in events:
		await _play_event(event)
	_finish_combat()


func _build_battle_states() -> Array[BattleCardState]:
	_bindings_by_id.clear()
	var states: Array[BattleCardState] = []
	var next_id := 0
	for slot in arena.get_all_slots():
		var card := slot.get_card()
		if not card or not card.card_data:
			continue
		var state := BattleCardState.new(
			next_id,
			card.card_data,
			slot.team,
			slot.slot_index,
			card.get_card_tier()
		)
		states.append(state)
		_bindings_by_id[next_id] = BattleCardBinding.new(card, slot)
		card.reset_combat_visuals()
		if not card.stat_changed.is_connected(_on_stat_changed):
			card.stat_changed.connect(_on_stat_changed)
		card.set_interaction_blocked(true, true)
		next_id += 1
	return states


func _play_event(event: Dictionary) -> void:
	match event["type"]:
		"combat_started":
			combat_started.emit()
		"tick":
			await _play_tick(event)
		"buff_applied":
			await _play_buff(event)
		"temporary_attack_applied":
			await _play_temporary_attack(event)
		"before_attack":
			await _play_before_attack(event)
		"attack_missed":
			await _play_attack_missed(event)
		"damage_applied":
			await _play_damage(event)
		"effect_damage_group":
			await _play_effect_damage_group(event)
		"effect_triggered":
			await _play_effect_triggered(event)
		"heal_applied":
			await _play_heal(event)
		"poison_applied":
			await _play_poison_applied(event)
		"poison_damage":
			await _play_poison_damage(event)
		"death_prevented":
			await _play_death_prevented(event)
		"card_died":
			_play_death(event)


func _play_tick(event: Dictionary) -> void:
	await get_tree().create_timer(cooldown_tick_seconds).timeout
	var cooldowns: Dictionary = event["cooldowns"]
	for card_id in cooldowns:
		var binding := _get_binding(int(card_id))
		if binding:
			binding.visual.set_cooldown_value(int(cooldowns[card_id]), false)


func _play_buff(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := int(event["source_id"])
	var target_id := int(event["target_id"])
	var source := _get_binding(source_id)
	var target := _get_binding(target_id)
	if not source or not target:
		return
	await buff_effect.play(source.visual, target.visual, CardStat.Type.ATTACK, int(event["amount"]))
	target.visual.set_attack_value(int(event["result"]))
	buff_applied.emit(source_id, target_id, str(event["stat"]), int(event["amount"]))
	await _wait_for_effect_time(effect_start_ms)


func _play_temporary_attack(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := int(event["source_id"])
	var target_id := int(event["target_id"])
	var source := _get_binding(source_id)
	var target := _get_binding(target_id)
	if not source or not target:
		return
	var amount := int(event["amount"])
	var result := int(event["result"])
	effect_popup.show_text(target.visual, "Temporary Damage", CardStat.TEMPORARY_ATTACK_COLOR)
	await buff_effect.play(source.visual, target.visual, CardStat.Type.TEMPORARY_ATTACK, amount)
	target.visual.set_temporary_attack_value(result)
	temporary_attack_applied.emit(source_id, target_id, amount, result)
	await _wait_for_effect_time(effect_start_ms)


func _play_heal(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := int(event["source_id"])
	var target_id := int(event["target_id"])
	var source := _get_binding(source_id)
	var target := _get_binding(target_id)
	if not source or not target:
		return
	var amount := int(event["amount"])
	await buff_effect.play(source.visual, target.visual, CardStat.Type.HEALTH, amount)
	target.visual.set_health_value(int(event["target_health"]))
	heal_applied.emit(source_id, target_id, amount, int(event["target_health"]))
	await _wait_for_effect_time(effect_start_ms)


func _play_poison_applied(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source := _get_binding(int(event["source_id"]))
	var target := _get_binding(int(event["target_id"]))
	if not source or not target:
		return
	effect_popup.show_text(target.visual, "Poisoned", CardStat.POISON_FEEDBACK_COLOR)
	await buff_effect.play(source.visual, target.visual, CardStat.Type.POISON, int(event["amount"]))
	target.visual.set_poison_value(int(event["result"]))
	poison_applied.emit(int(event["source_id"]), int(event["target_id"]), int(event["amount"]), int(event["result"]))
	await _wait_for_effect_time(effect_start_ms)


func _play_poison_damage(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var target := _get_binding(int(event["target_id"]))
	if not target:
		return
	var damage := int(event["damage"])
	await buff_effect.play_stat_to_stat(
		target.visual,
		CardStat.Type.POISON,
		CardStat.Type.HEALTH,
		damage
	)
	target.visual.set_health_value(int(event["target_health"]))
	target.visual.set_poison_value(int(event["poison_remaining"]))
	damage_applied.emit(int(event["target_id"]), damage, int(event["target_health"]))
	poison_damage_applied.emit(int(event["target_id"]), damage, int(event["target_health"]))
	await _wait_for_effect_time(effect_start_ms)


func _play_death_prevented(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var card_id := int(event["card_id"])
	var binding := _get_binding(card_id)
	if not binding:
		return
	var effect_name := str(event["effect_name"])
	effect_popup.show_text(binding.visual, effect_name, Color(str(event["effect_color"])))
	binding.visual.set_health_value(int(event["target_health"]))
	binding.visual.set_poison_value(int(event["poison_remaining"]))
	death_prevented.emit(card_id, effect_name, int(event["target_health"]))
	await binding.visual.play_survival_animation()
	await _wait_for_effect_time(effect_start_ms)


func _on_stat_changed(card: CardVisual, stat_type: CardStat.Type, delta: int) -> void:
	stat_popup.show_change(card, stat_type, delta)


func _play_before_attack(event: Dictionary) -> void:
	var attacker_id := int(event["attacker_id"])
	var target_id := int(event["target_id"])
	var attacker := _get_binding(attacker_id)
	var target := _get_binding(target_id)
	if not attacker or not target:
		return
	before_attack.emit(attacker_id, target_id)
	await attacker.visual.play_attack_to_impact(target.visual.get_card_center())
	attacker.visual.start_attack_return()


func _play_attack_missed(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var attacker_id := int(event["attacker_id"])
	var target_id := int(event["target_id"])
	var attacker := _get_binding(attacker_id)
	var target := _get_binding(target_id)
	if not attacker or not target:
		return
	var midpoint := float(BattleArena.TEAM_SIZE) * 0.5
	var dodge_direction := -1.0 if target.slot.slot_index < midpoint else 1.0
	effect_popup.show_text(
		target.visual,
		str(event["effect_name"]),
		Color(str(event["effect_color"]))
	)
	await target.visual.play_dodge_animation(dodge_direction)
	while is_instance_valid(attacker.visual) and attacker.visual.is_attack_returning():
		await get_tree().process_frame
	if is_instance_valid(attacker.visual):
		attacker.visual.set_temporary_attack_value(int(event["temporary_attack_remaining"]))
		attacker.visual.set_cooldown_value(int(event["attacker_cooldown"]), false)
	attack_missed.emit(attacker_id, target_id)
	await _wait_for_effect_time(effect_start_ms)


func _play_damage(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var attacker_id := int(event["attacker_id"])
	var target_id := int(event["target_id"])
	var attacker := _get_binding(attacker_id)
	var target := _get_binding(target_id)
	if not attacker or not target:
		return
	var remaining_health := int(event["target_health"])
	target.visual.set_health_value(remaining_health)
	damage_applied.emit(target_id, int(event["damage"]), remaining_health)
	if int(event["damage"]) <= 0:
		effect_popup.show_text(target.visual, "Block")
		await block_effect.play(target.visual)
	else:
		await target.visual.play_hit_animation(attacker.visual.get_card_center())
	while is_instance_valid(attacker.visual) and attacker.visual.is_attack_returning():
		await get_tree().process_frame
	if is_instance_valid(attacker.visual):
		attacker.visual.set_temporary_attack_value(int(event["temporary_attack_remaining"]))
		attacker.visual.set_cooldown_value(int(event["attacker_cooldown"]), false)
	await _wait_for_effect_time(effect_start_ms)


func _play_effect_damage_group(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var source_id := int(event["source_id"])
	var source := _get_binding(source_id)
	if not source:
		return
	var hit_tweens: Array[Tween] = []
	var hits: Array = event["hits"]
	for hit_value in hits:
		var hit: Dictionary = hit_value
		var target_id := int(hit["target_id"])
		var target := _get_binding(target_id)
		if not target:
			continue
		var damage := int(hit["damage"])
		var remaining_health := int(hit["target_health"])
		target.visual.set_health_value(remaining_health)
		damage_applied.emit(target_id, damage, remaining_health)
		effect_damage_applied.emit(source_id, target_id, damage, remaining_health)
		hit_tweens.append(target.visual.start_hit_animation(source.visual.get_card_center()))
	if not hit_tweens.is_empty():
		await hit_tweens[0].finished
	await _wait_for_effect_time(effect_start_ms)


func _play_effect_triggered(event: Dictionary) -> void:
	var effect_start_ms := Time.get_ticks_msec()
	var binding := _get_binding(int(event["card_id"]))
	if not binding:
		return
	effect_popup.show_text(
		binding.visual,
		str(event["effect_name"]),
		Color(str(event["effect_color"]))
	)
	await _wait_for_effect_time(effect_start_ms)


func _play_death(event: Dictionary) -> void:
	var card_id := int(event["card_id"])
	var binding := _get_binding(card_id)
	if not binding:
		return
	binding.slot.release(binding.visual)
	binding.visual.play_death_animation()
	binding.visual.queue_free()
	_bindings_by_id.erase(card_id)
	card_died.emit(card_id)


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
	combat_finished.emit()
