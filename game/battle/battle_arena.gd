class_name BattleArena
extends Control

const TEAM_SIZE := 4
const SLOT_SIZE := CardMetrics.SIZE
const ADJACENT_SLOT_MARGIN := 25.0
const CENTER_MARGIN := 160.0
const CARD_SLOT_SCENE := preload("res://game/battle/card_slot.tscn")
const CARD_SCENE := preload("res://game/cards/card_template.tscn")

@onready var top_slots: HBoxContainer = %TopSlots
@onready var bottom_slots: HBoxContainer = %BottomSlots
@onready var combat: BattleCombat = $Combat

var _shop_active := false
var _slots_locked := false
var _remote_cards: Array[CardVisual] = []


func _ready() -> void:
	_build_arena()
	get_viewport().size_changed.connect(_center_arena)


func _build_arena() -> void:
	var row_width := SLOT_SIZE.x * TEAM_SIZE + ADJACENT_SLOT_MARGIN * (TEAM_SIZE - 1)
	var arena_size := Vector2(row_width, SLOT_SIZE.y * 2.0 + CENTER_MARGIN)
	custom_minimum_size = arena_size
	size = arena_size

	_configure_row(top_slots, Vector2.ZERO, row_width)
	_configure_row(bottom_slots, Vector2(0.0, SLOT_SIZE.y + CENTER_MARGIN), row_width)
	_configure_slots(top_slots, "Top", CardSlot.TEAM_ENEMY)
	_configure_slots(bottom_slots, "Bottom", CardSlot.TEAM_PLAYER)
	_center_arena()


func _center_arena() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	global_position = viewport_rect.position + (viewport_rect.size - size) * 0.5


func _configure_row(row: HBoxContainer, row_position: Vector2, row_width: float) -> void:
	row.position = row_position
	row.size = Vector2(row_width, SLOT_SIZE.y)
	row.add_theme_constant_override("separation", int(ADJACENT_SLOT_MARGIN))


func _configure_slots(row: HBoxContainer, prefix: String, team: int) -> void:
	var slots: Array[CardSlot] = _get_slots(row)
	while slots.size() < TEAM_SIZE:
		var slot := CARD_SLOT_SCENE.instantiate() as CardSlot
		row.add_child(slot)
		slots.append(slot)
	while slots.size() > TEAM_SIZE:
		var extra_slot: CardSlot = slots.pop_back()
		row.remove_child(extra_slot)
		extra_slot.queue_free()
	for index in range(slots.size()):
		var slot: CardSlot = slots[index]
		slot.name = "%sSlot%d" % [prefix, index + 1]
		slot.team = team
		slot.slot_index = index
		slot.custom_minimum_size = SLOT_SIZE


func get_enemy_slots() -> Array[CardSlot]:
	return _get_slots(top_slots)


func get_player_slots() -> Array[CardSlot]:
	return _get_slots(bottom_slots)


func get_all_slots() -> Array[CardSlot]:
	var slots := get_player_slots()
	slots.append_array(get_enemy_slots())
	return slots


func set_shop_active(active: bool) -> void:
	_shop_active = active


func set_slots_locked(locked: bool) -> void:
	_slots_locked = locked
	for slot in get_all_slots():
		slot.accepts_cards = not locked


func show_remote_board(payload: Array) -> void:
	clear_remote_board()
	for value in payload:
		var entry := BattleBoardSnapshot._payload_entry(value)
		if not entry:
			continue
		var slot: CardSlot = _find_slot(CardSlot.TEAM_ENEMY, entry.slot_index)
		var card: CardVisual = _spawn_card_from_entry(entry, slot, true)
		if card:
			_remote_cards.append(card)


func restore_player_board(payload: Array) -> void:
	clear_player_board()
	for value in payload:
		var entry := BattleBoardSnapshot._payload_entry(value)
		if not entry:
			continue
		_spawn_card_from_entry(
			entry,
			_find_slot(CardSlot.TEAM_PLAYER, entry.slot_index),
			false
		)


func clear_remote_board() -> void:
	for slot in get_enemy_slots():
		var card: CardVisual = slot.get_card()
		if card and _remote_cards.has(card):
			slot.release(card)
	for card in _remote_cards:
		if is_instance_valid(card):
			card.queue_free()
	_remote_cards.clear()


func clear_player_board() -> void:
	for slot in get_player_slots():
		var card: CardVisual = slot.get_card()
		if card:
			slot.release(card)
			card.hide()
			card.queue_free()


func reset_board() -> void:
	clear_remote_board()
	clear_player_board()


func _find_slot(team: int, slot_index: int) -> CardSlot:
	for slot in get_all_slots():
		if slot.team == team and slot.slot_index == slot_index:
			return slot
	return null


func _spawn_card_from_entry(entry: BattleBoardCardSnapshot, slot: CardSlot, blocked: bool) -> CardVisual:
	if not slot or slot.has_card():
		return null
	var data: CardData = load(entry.card_id) as CardData
	if not data:
		return null
	var card: CardVisual = CARD_SCENE.instantiate() as CardVisual
	card.card_data = data
	add_child(card)
	card.set_card_tier(entry.tier)
	card.global_position = slot.get_snap_position(card.card_size)
	card.set_interaction_blocked(blocked, blocked)
	slot.occupy(card)
	return card


func _get_slots(row: HBoxContainer) -> Array[CardSlot]:
	var slots: Array[CardSlot] = []
	for child in row.get_children():
		var slot := child as CardSlot
		if slot:
			slots.append(slot)
	return slots
