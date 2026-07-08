class_name CardCollection
extends CanvasLayer

const CARD_SCENE := preload("res://game/cards/card_template.tscn")
const GHOST_SCENE := preload("res://game/shop/card_collection/inventory_ghost_slot.tscn")
const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")

@export_group("Inventory Layout")
@export_range(0.0, 300.0, 1.0) var top_margin := 0.0
@export_range(0.0, 300.0, 1.0) var left_margin := 15.0
@export_range(0, 80, 1) var card_spacing := 20
@export_range(0, 100, 1) var content_padding := 50

@export_group("Inventory Hover")
@export_range(1.0, 1.4, 0.01) var preview_hover_scale := 1.15
@export_range(0.0, 24.0, 1.0) var preview_hover_lift := 8.0

@export_group("Inventory Animation")
@export_range(0.05, 0.6, 0.01) var slide_duration := 0.22
@export_range(0.0, 100.0, 1.0) var slide_distance := 40.0
@export_range(0.05, 0.6, 0.01) var reorganize_duration := 0.22
@export_range(0.0, 0.5, 0.01) var reorganize_delay := 0.08
@export_range(0.05, 0.6, 0.01) var ghost_return_duration := 0.18
@export_range(0.05, 1.0, 0.05) var spawn_start_scale := 0.25

@export_group("Button")
@export_range(1.0, 1.2, 0.01) var button_hover_scale := 1.06
@export_range(0.05, 0.4, 0.01) var button_hover_duration := 0.12

@onready var interface: Control = %Interface
@onready var cards_button: Button = %CardsButton
@onready var cards_panel: Panel = %CardsPanel
@onready var cards_scroll: ScrollContainer = %Scroll
@onready var content_margin: MarginContainer = %ContentMargin
@onready var cards_grid: GridContainer = %CardsGrid
@onready var animator: CardCollectionAnimator = %Animator

var _entries: Array[CardCollectionEntry] = []
var _active_drags: Dictionary = {}
var _pending_merges: Dictionary = {}
var _collecting_card_ids: Array[int] = []
var _next_entry_id := 1
var _panel_animating := false
var _reorganize_revision := 0
var _button_tween: Tween
var _reorganize_tween: Tween
var _choice_locked := false


func _ready() -> void:
	add_to_group("card_collections")
	cards_panel.hide()
	_layout_panel()
	_configure_button()
	cards_button.pressed.connect(_toggle_panel)
	get_viewport().size_changed.connect(_layout_panel)
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().get_nodes_in_group("card_visuals"):
		_connect_card(node as CardVisual)


func _layout_panel() -> void:
	var viewport_height := get_viewport().get_visible_rect().size.y
	cards_panel.offset_left = left_margin
	cards_panel.offset_top = top_margin - viewport_height
	cards_panel.offset_right = (
		cards_panel.offset_left + CardMetrics.SIZE.x * 2.0 + card_spacing + content_padding * 2.0
	)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		content_margin.add_theme_constant_override(side, content_padding)
	cards_grid.add_theme_constant_override("h_separation", card_spacing)
	cards_grid.add_theme_constant_override("v_separation", card_spacing)
	cards_button.pivot_offset = cards_button.size * 0.5


func _configure_button() -> void:
	UIButtonStyle.apply_plain_button(cards_button, 24, LIGHT_COLOR, DARK_COLOR)
	cards_button.mouse_entered.connect(_animate_button_hover.bind(true))
	cards_button.mouse_exited.connect(_animate_button_hover.bind(false))
	_set_button_active(false)


func _animate_button_hover(hovered: bool) -> void:
	if _button_tween:
		_button_tween.kill()
	_button_tween = create_tween()
	_button_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_button_tween.tween_property(
		cards_button,
		"scale",
		Vector2.ONE * (button_hover_scale if hovered else 1.0),
		button_hover_duration
	)


func _set_button_active(active: bool) -> void:
	var text_color: Color = LIGHT_COLOR if active else DARK_COLOR
	UIButtonStyle.set_button_colors(cards_button, DARK_COLOR if active else LIGHT_COLOR, text_color)


func _on_node_added(node: Node) -> void:
	var card := node as CardVisual
	if card:
		_connect_card(card)


func _connect_card(card: CardVisual) -> void:
	if card and not card.invalid_drop_requested.is_connected(_on_invalid_drop):
		card.invalid_drop_requested.connect(_on_invalid_drop)


func _on_invalid_drop(card: CardVisual) -> void:
	collect_card(card)


func collect_card(card: CardVisual) -> void:
	if not is_instance_valid(card) or not card.card_data:
		return
	var instance_id := card.get_instance_id()
	if _collecting_card_ids.has(instance_id):
		return
	_collecting_card_ids.append(instance_id)
	var active_drag := _get_active_drag(instance_id)
	if active_drag:
		await _return_to_ghost(card, active_drag)
		_collecting_card_ids.erase(instance_id)
		return
	var data := card.card_data
	var tier := card.get_card_tier()
	await animator.play(card, cards_button.get_global_rect().get_center())
	_collecting_card_ids.erase(instance_id)
	if is_instance_valid(card):
		card.queue_free()
	_add_entry(data, tier)


func set_choice_locked(locked: bool) -> void:
	_choice_locked = locked
	cards_button.disabled = locked
	while locked and _panel_animating:
		await get_tree().process_frame
	if locked and cards_panel.visible:
		await _close_panel()


func reset_collection() -> void:
	_cancel_reorganization()
	for child in interface.get_children():
		var card := child as CardVisual
		if card and _active_drags.has(card.get_instance_id()):
			card.queue_free()
	_entries.clear()
	_active_drags.clear()
	_pending_merges.clear()
	_collecting_card_ids.clear()
	_next_entry_id = 1
	for child in cards_grid.get_children():
		child.queue_free()
	cards_panel.hide()
	_panel_animating = false
	_choice_locked = false
	cards_button.disabled = false
	_set_button_active(false)


func _return_to_ghost(card: CardVisual, active_drag: CardCollectionDragState) -> void:
	var ghost := active_drag.get_ghost()
	if not ghost:
		var fallback_entry: CardCollectionEntry = active_drag.entry
		_remove_active_drag(card.get_instance_id())
		_entries.append(fallback_entry)
		card.queue_free()
		if cards_panel.visible:
			_reorganize(_capture_entry_positions())
		return
	_disconnect_drag_outcomes(card)
	card.set_interaction_blocked(true)
	var target_position := ghost.global_position + (ghost.size - card.size) * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "global_position", target_position, ghost_return_duration)
	tween.tween_property(card.card_surface, "position", Vector2.ZERO, ghost_return_duration)
	tween.tween_property(card.card_surface, "rotation_degrees", 0.0, ghost_return_duration)
	tween.tween_property(card.card_surface, "scale", Vector2.ONE, ghost_return_duration)
	await tween.finished
	if not is_instance_valid(card) or not is_instance_valid(ghost):
		return
	var entry: CardCollectionEntry = active_drag.entry
	var grid_index := ghost.get_index()
	ghost.get_parent().remove_child(ghost)
	ghost.queue_free()
	_active_drags.erase(card.get_instance_id())
	_entries.append(entry)
	_entries.sort_custom(_sort_entries)
	card.set_meta("collection_entry_id", entry.id)
	card.set_meta("collection_hover_scale", card.hover_scale)
	card.set_meta("collection_hover_lift", card.hover_lift)
	card.hover_scale = preview_hover_scale
	card.hover_lift = preview_hover_lift
	card.reparent(cards_grid, true)
	cards_grid.move_child(card, grid_index)
	card.set_interaction_blocked(false)


func _disconnect_drag_outcomes(card: CardVisual) -> void:
	if card.slotted.is_connected(_on_inventory_card_slotted):
		card.slotted.disconnect(_on_inventory_card_slotted)
	if card.merge_started.is_connected(_on_inventory_merge_started):
		card.merge_started.disconnect(_on_inventory_merge_started)


func _add_entry(data: CardData, tier: int) -> void:
	var old_positions := _capture_entry_positions()
	_entries.append(CardCollectionEntry.new(_next_entry_id, data, tier))
	_next_entry_id += 1
	if cards_panel.visible:
		_reorganize(old_positions)


func _toggle_panel() -> void:
	if _choice_locked or _panel_animating:
		return
	if cards_panel.visible:
		_close_panel()
	else:
		_open_panel()


func _open_panel() -> void:
	_panel_animating = true
	_cancel_reorganization()
	_set_button_active(true)
	cards_panel.show()
	_refresh_cards()
	await get_tree().process_frame
	cards_scroll.scroll_vertical = 0
	await _animate_panel(true)
	_panel_animating = false


func _close_panel() -> void:
	_panel_animating = true
	_set_button_active(false)
	await _animate_panel(false)
	cards_panel.hide()
	_panel_animating = false


func _refresh_cards() -> void:
	_entries.sort_custom(_sort_entries)
	var existing := {}
	for card in _get_previews():
		existing[int(card.get_meta("collection_entry_id"))] = card
	var kept := {}
	for index in range(_entries.size()):
		var entry: CardCollectionEntry = _entries[index]
		var entry_id := entry.id
		var card := existing.get(entry_id) as CardVisual
		if not card:
			card = _create_preview(entry)
		else:
			card.set_card_tier(entry.tier)
		kept[entry_id] = true
		cards_grid.move_child(card, index)
	for entry_id in existing:
		if kept.has(entry_id):
			continue
		var stale_card := existing[entry_id] as CardVisual
		cards_grid.remove_child(stale_card)
		stale_card.queue_free()


func _create_preview(entry: CardCollectionEntry) -> CardVisual:
	var card := CARD_SCENE.instantiate() as CardVisual
	var entry_id := entry.id
	card.card_data = entry.data
	card.set_meta("collection_entry_id", entry_id)
	card.set_meta("collection_hover_scale", card.hover_scale)
	card.set_meta("collection_hover_lift", card.hover_lift)
	card.hover_scale = preview_hover_scale
	card.hover_lift = preview_hover_lift
	card.drag_started.connect(_on_preview_drag_started.bind(entry_id))
	cards_grid.add_child(card)
	card.set_card_tier(entry.tier)
	card.tier_changed.connect(_on_preview_tier_changed.bind(entry_id))
	card.merge_animator.merge_finished.connect(
		_on_stored_preview_merge_finished.bind(entry_id)
	)
	return card


func _sort_entries(left: CardCollectionEntry, right: CardCollectionEntry) -> bool:
	var left_data := left.data
	var right_data := right.data
	if left_data.rarity != right_data.rarity:
		return left_data.rarity > right_data.rarity
	if left.tier != right.tier:
		return left.tier > right.tier
	if left_data.title != right_data.title:
		return left_data.title.naturalnocasecmp_to(right_data.title) < 0
	return left.id < right.id


func _on_preview_drag_started(card: CardVisual, entry_id: int) -> void:
	var entry := _find_entry(entry_id)
	if not entry:
		return
	var ghost := GHOST_SCENE.instantiate() as Control
	ghost.custom_minimum_size = CardMetrics.SIZE
	ghost.set_meta("collection_entry_id", entry_id)
	var grid_index := card.get_index()
	cards_grid.add_child(ghost)
	cards_grid.move_child(ghost, grid_index)
	_active_drags[card.get_instance_id()] = CardCollectionDragState.new(
		entry.duplicate_entry(),
		ghost.get_instance_id()
	)
	_remove_entry(entry_id)
	_restore_world_hover(card)
	card.remove_meta("collection_entry_id")
	card.reparent(interface, true)
	card.slotted.connect(_on_inventory_card_slotted, CONNECT_ONE_SHOT)
	card.merge_started.connect(_on_inventory_merge_started, CONNECT_ONE_SHOT)


func _on_inventory_card_slotted(card: CardVisual) -> void:
	if card.merge_started.is_connected(_on_inventory_merge_started):
		card.merge_started.disconnect(_on_inventory_merge_started)
	var old_positions := _capture_entry_positions()
	_finalize_departure(card.get_instance_id())
	card.reparent(get_tree().current_scene, true)
	_reorganize(old_positions)


func _on_inventory_merge_started(source: CardVisual, target: CardVisual) -> void:
	if source.slotted.is_connected(_on_inventory_card_slotted):
		source.slotted.disconnect(_on_inventory_card_slotted)
	var source_id := source.get_instance_id()
	_pending_merges[target.get_instance_id()] = source_id
	target.merge_animator.merge_finished.connect(_on_inventory_merge_finished, CONNECT_ONE_SHOT)


func _on_inventory_merge_finished(target: CardVisual) -> void:
	var target_id := target.get_instance_id()
	var source_id := int(_pending_merges.get(target_id, 0))
	_pending_merges.erase(target_id)
	if source_id == 0:
		return
	var old_positions := _capture_entry_positions()
	_finalize_departure(source_id)
	_reorganize(old_positions)


func _on_stored_preview_merge_finished(target: CardVisual, _entry_id: int) -> void:
	if _pending_merges.has(target.get_instance_id()):
		return
	_reorganize(_capture_entry_positions())


func _on_preview_tier_changed(_card: CardVisual, tier: int, entry_id: int) -> void:
	var entry := _find_entry(entry_id)
	if entry:
		entry.tier = tier


func _finalize_departure(card_instance_id: int) -> void:
	if not _get_active_drag(card_instance_id):
		return
	_remove_active_drag(card_instance_id)


func forget_dragged_card(card: CardVisual) -> void:
	if is_instance_valid(card):
		_finalize_departure(card.get_instance_id())


func _remove_active_drag(card_instance_id: int) -> void:
	var active_drag := _get_active_drag(card_instance_id)
	if not active_drag:
		return
	var ghost := active_drag.get_ghost()
	if ghost:
		if ghost.get_parent():
			ghost.get_parent().remove_child(ghost)
		ghost.queue_free()
	_active_drags.erase(card_instance_id)


func _get_active_drag(card_instance_id: int) -> CardCollectionDragState:
	return _active_drags.get(card_instance_id) as CardCollectionDragState


func _restore_world_hover(card: CardVisual) -> void:
	card.hover_scale = float(card.get_meta("collection_hover_scale", card.hover_scale))
	card.hover_lift = float(card.get_meta("collection_hover_lift", card.hover_lift))
	card.remove_meta("collection_hover_scale")
	card.remove_meta("collection_hover_lift")


func _reorganize(old_positions: Dictionary) -> void:
	_cancel_reorganization()
	var revision := _reorganize_revision
	_refresh_cards()
	cards_grid.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var cards := _get_previews()
	if cards.is_empty():
		return
	for card in cards:
		var entry_id := int(card.get_meta("collection_entry_id"))
		card.set_interaction_blocked(true)
		if old_positions.has(entry_id):
			card.card_surface.position = old_positions[entry_id] - card.global_position
		else:
			card.card_surface.position = Vector2.ZERO
			card.card_surface.scale = Vector2.ONE * spawn_start_scale
		card.self_modulate.a = 1.0
	if reorganize_delay > 0.0:
		await get_tree().create_timer(reorganize_delay).timeout
	if revision != _reorganize_revision:
		return
	_reorganize_tween = create_tween().set_parallel(true)
	_reorganize_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for card in cards:
		if not is_instance_valid(card):
			continue
		_reorganize_tween.tween_property(card.card_surface, "position", Vector2.ZERO, reorganize_duration)
		var entry_id := int(card.get_meta("collection_entry_id"))
		if not old_positions.has(entry_id):
			_reorganize_tween.tween_property(
				card.card_surface,
				"scale",
				Vector2.ONE,
				reorganize_duration
			).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _reorganize_tween.finished
	if revision != _reorganize_revision:
		return
	_reorganize_tween = null
	for card in cards:
		if is_instance_valid(card):
			card.set_interaction_blocked(false)


func _cancel_reorganization() -> void:
	_reorganize_revision += 1
	if _reorganize_tween:
		_reorganize_tween.kill()
		_reorganize_tween = null
	for card in _get_previews():
		card.card_surface.position = Vector2.ZERO
		card.card_surface.scale = Vector2.ONE
		card.self_modulate.a = 1.0
		card.set_interaction_blocked(false)


func _animate_panel(opening: bool) -> void:
	var final_position := cards_panel.position
	_set_previews_blocked(true)
	if opening:
		cards_panel.position = final_position + Vector2.DOWN * slide_distance
		cards_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT if opening else Tween.EASE_IN)
	tween.tween_property(
		cards_panel,
		"position",
		final_position if opening else final_position + Vector2.DOWN * slide_distance,
		slide_duration
	)
	tween.tween_property(
		cards_panel,
		"modulate:a",
		1.0 if opening else 0.0,
		slide_duration
	)
	await tween.finished
	if opening:
		_set_previews_blocked(false)
	else:
		cards_panel.position = final_position
		cards_panel.modulate.a = 1.0


func _set_previews_blocked(blocked: bool) -> void:
	for card in _get_previews():
		card.set_interaction_blocked(blocked)


func _capture_entry_positions() -> Dictionary:
	var positions := {}
	for child in cards_grid.get_children():
		if child.has_meta("collection_entry_id"):
			positions[int(child.get_meta("collection_entry_id"))] = child.global_position
	return positions


func _get_previews() -> Array[CardVisual]:
	var cards: Array[CardVisual] = []
	for child in cards_grid.get_children():
		var card := child as CardVisual
		if card:
			cards.append(card)
	return cards


func _remove_entry(entry_id: int) -> void:
	for index in range(_entries.size()):
		if _entries[index].id == entry_id:
			_entries.remove_at(index)
			return


func _find_entry(entry_id: int) -> CardCollectionEntry:
	for entry in _entries:
		if entry.id == entry_id:
			return entry
	return null
