class_name DebugCardMenu
extends CanvasLayer

const CARD_CATALOG: CardCatalog = preload("res://content/cards/all_cards.tres")
const CARD_SCENE := preload("res://game/cards/card_template.tscn")

@onready var overlay: Control = %Overlay
@onready var cards_row: HBoxContainer = %CardsRow

var _is_open := false


func _ready() -> void:
	overlay.hide()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if (
		not key_event
		or key_event.keycode != KEY_J
		or not key_event.ctrl_pressed
		or not key_event.pressed
		or key_event.echo
	):
		return
	if _is_open:
		_close_menu()
	else:
		_open_menu()
	get_viewport().set_input_as_handled()


func _open_menu() -> void:
	_clear_previews()
	_set_world_cards_blocked(true)
	if CARD_CATALOG:
		for card_resource in CARD_CATALOG.cards:
			var card_data := card_resource as CardData
			if not card_data:
				continue
			var card := CARD_SCENE.instantiate() as CardVisual
			card.card_data = card_data
			card.set_meta("debug_preview", true)
			card.enable_tier_cycle_shortcut()
			card.drag_started.connect(_on_card_drag_started)
			cards_row.add_child(card)
	_is_open = true
	overlay.show()


func _close_menu() -> void:
	_is_open = false
	overlay.hide()
	_clear_previews()
	_set_world_cards_blocked(false)


func _on_card_drag_started(card: CardVisual) -> void:
	card.disable_tier_cycle_shortcut()
	card.reparent(get_tree().current_scene, true)
	card.remove_meta("debug_preview")
	card.set_interaction_blocked(false)
	_is_open = false
	overlay.hide()
	_clear_previews()
	_set_world_cards_blocked(false)


func _clear_previews() -> void:
	for child in cards_row.get_children():
		child.queue_free()


func _set_world_cards_blocked(blocked: bool) -> void:
	for node in get_tree().get_nodes_in_group("card_visuals"):
		var card := node as CardVisual
		if card and not card.has_meta("debug_preview"):
			card.set_interaction_blocked(blocked)
