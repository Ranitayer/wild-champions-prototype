class_name DebugCardMenu
extends CanvasLayer

const CARD_CATALOG: CardCatalog = preload("res://content/cards/all_cards.tres")
const CARD_SCENE := preload("res://game/cards/card_template.tscn")
const SCREEN_MARGIN := 56.0
const CARD_GAP := 24.0

@onready var overlay: Control = %Overlay
@onready var cards_area: Control = %CardsArea

var _is_open := false
var _preview_hover_z: int = 0


func _ready() -> void:
	overlay.hide()
	get_viewport().size_changed.connect(_layout_previews)


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventMouse and _is_over_preview_card(get_viewport().get_mouse_position()):
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	var toggled_menu: bool = (
		key_event != null
		and key_event.keycode == KEY_J
		and key_event.ctrl_pressed
		and key_event.pressed
		and not key_event.echo
	)
	if not toggled_menu:
		if _is_open:
			get_viewport().set_input_as_handled()
		return
	if _is_open:
		_close_menu()
	else:
		_open_menu()
	get_viewport().set_input_as_handled()


func _open_menu() -> void:
	_clear_previews()
	_set_world_cards_blocked(true)
	_set_shop_purchasables_blocked(true)
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
			card.hover_changed.connect(_on_preview_card_hover_changed)
			cards_area.add_child(card)
	_is_open = true
	overlay.show()
	_layout_previews()


func _close_menu() -> void:
	_is_open = false
	overlay.hide()
	_clear_previews()
	_set_world_cards_blocked(false)
	_set_shop_purchasables_blocked(false)


func _on_card_drag_started(card: CardVisual) -> void:
	card.disable_tier_cycle_shortcut()
	card.reparent(get_tree().current_scene, true)
	card.scale = Vector2.ONE
	card.remove_meta("debug_preview")
	card.set_interaction_blocked(false)
	_is_open = false
	overlay.hide()
	_clear_previews()
	_set_world_cards_blocked(false)
	_set_shop_purchasables_blocked(false)


func _on_preview_card_hover_changed(card: CardVisual, hovered: bool) -> void:
	if not hovered:
		return
	_preview_hover_z += 1
	card.z_index = _preview_hover_z
	if card.get_parent() == cards_area:
		cards_area.move_child(card, cards_area.get_child_count() - 1)


func _is_over_preview_card(point: Vector2) -> bool:
	for child in cards_area.get_children():
		var card: CardVisual = child as CardVisual
		if card and card._contains_visual_point(point):
			return true
	return false


func _clear_previews() -> void:
	for child in cards_area.get_children():
		child.queue_free()


func _set_world_cards_blocked(blocked: bool) -> void:
	for node in get_tree().get_nodes_in_group("card_visuals"):
		var card := node as CardVisual
		if card and not card.has_meta("debug_preview"):
			card.set_interaction_blocked(blocked)


func _set_shop_purchasables_blocked(blocked: bool) -> void:
	for node in get_tree().get_nodes_in_group("shop_purchasables"):
		if node.has_method("set_payment_pending"):
			node.set_payment_pending(blocked)


func _layout_previews() -> void:
	if not _is_open:
		return
	var cards: Array[Node] = cards_area.get_children()
	var count: int = cards.size()
	if count == 0:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var available: Vector2 = Vector2(
		maxf(CardMetrics.SIZE.x, viewport_size.x - SCREEN_MARGIN * 2.0),
		maxf(CardMetrics.SIZE.y, viewport_size.y - SCREEN_MARGIN * 2.0)
	)
	var best_columns := 1
	var best_scale := 0.0

	for columns in range(1, count + 1):
		var candidate_rows: int = ceili(float(count) / float(columns))
		var raw_size: Vector2 = Vector2(
			columns * CardMetrics.SIZE.x + (columns - 1) * CARD_GAP,
			candidate_rows * CardMetrics.SIZE.y + (candidate_rows - 1) * CARD_GAP
		)
		var preview_scale: float = minf(1.0, minf(available.x / raw_size.x, available.y / raw_size.y))
		if preview_scale > best_scale:
			best_columns = columns
			best_scale = preview_scale

	var row_count: int = ceili(float(count) / float(best_columns))
	var scaled_card: Vector2 = CardMetrics.SIZE * best_scale
	var scaled_gap: float = CARD_GAP * best_scale
	var grid_size: Vector2 = Vector2(
		best_columns * scaled_card.x + (best_columns - 1) * scaled_gap,
		row_count * scaled_card.y + (row_count - 1) * scaled_gap
	)
	var start: Vector2 = (viewport_size - grid_size) * 0.5

	for index in range(count):
		var card := cards[index] as Control
		if not card:
			continue
		var column: int = index % best_columns
		var row: int = floori(float(index) / float(best_columns))
		card.scale = Vector2.ONE * best_scale
		card.position = start + Vector2(
			column * (scaled_card.x + scaled_gap),
			row * (scaled_card.y + scaled_gap)
		)
