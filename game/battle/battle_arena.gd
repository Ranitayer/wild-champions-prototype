class_name BattleArena
extends Control

const TEAM_SIZE := 4
const SLOT_SIZE := Vector2(200.0, 275.0)
const ADJACENT_SLOT_MARGIN := 25.0
const CENTER_MARGIN := 160.0
const CARD_SLOT_SCENE := preload("res://game/battle/card_slot.tscn")

@onready var top_slots: HBoxContainer = %TopSlots
@onready var bottom_slots: HBoxContainer = %BottomSlots
@onready var combat: BattleCombat = $Combat


func _ready() -> void:
	_build_arena()
	get_viewport().size_changed.connect(_center_arena)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not key_event or key_event.keycode != KEY_SPACE or not key_event.pressed or key_event.echo:
		return
	if combat.start_combat():
		get_viewport().set_input_as_handled()


func _build_arena() -> void:
	var row_width := SLOT_SIZE.x * TEAM_SIZE + ADJACENT_SLOT_MARGIN * (TEAM_SIZE - 1)
	var arena_size := Vector2(row_width, SLOT_SIZE.y * 2.0 + CENTER_MARGIN)
	custom_minimum_size = arena_size
	size = arena_size

	_configure_row(top_slots, Vector2.ZERO, row_width)
	_configure_row(bottom_slots, Vector2(0.0, SLOT_SIZE.y + CENTER_MARGIN), row_width)
	_create_slots(top_slots, "Top", CardSlot.TEAM_ENEMY)
	_create_slots(bottom_slots, "Bottom", CardSlot.TEAM_PLAYER)
	_center_arena()


func _center_arena() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	global_position = viewport_rect.position + (viewport_rect.size - size) * 0.5


func _configure_row(row: HBoxContainer, row_position: Vector2, row_width: float) -> void:
	row.position = row_position
	row.size = Vector2(row_width, SLOT_SIZE.y)
	row.add_theme_constant_override("separation", int(ADJACENT_SLOT_MARGIN))


func _create_slots(row: HBoxContainer, prefix: String, team: int) -> void:
	for child in row.get_children():
		child.queue_free()
	for index in range(TEAM_SIZE):
		var slot := CARD_SLOT_SCENE.instantiate() as CardSlot
		slot.name = "%sSlot%d" % [prefix, index + 1]
		slot.team = team
		slot.slot_index = index
		slot.custom_minimum_size = SLOT_SIZE
		row.add_child(slot)


func get_enemy_slots() -> Array[CardSlot]:
	return _get_slots(top_slots)


func get_player_slots() -> Array[CardSlot]:
	return _get_slots(bottom_slots)


func get_all_slots() -> Array[CardSlot]:
	var slots := get_player_slots()
	slots.append_array(get_enemy_slots())
	return slots


func _get_slots(row: HBoxContainer) -> Array[CardSlot]:
	var slots: Array[CardSlot] = []
	for child in row.get_children():
		var slot := child as CardSlot
		if slot:
			slots.append(slot)
	return slots
