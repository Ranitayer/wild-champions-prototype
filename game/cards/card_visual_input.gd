class_name CardVisualInput
extends RefCounted


static func handle_unhandled_input(card: CardVisual, event: InputEvent) -> void:
	if card._try_start_drag(event):
		card.get_viewport().set_input_as_handled()


static func handle_gui_input(card: CardVisual, event: InputEvent) -> void:
	if card._try_start_drag(event):
		card.accept_event()


static func handle_drag_input(card: CardVisual, event: InputEvent) -> void:
	if not card._dragging:
		return
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion:
		card.global_position = card.get_global_mouse_position() - card._drag_offset
		card._drag_tilt_target = clampf(
			mouse_motion.relative.x * card.drag_sway_sensitivity,
			-card.drag_max_sway,
			card.drag_max_sway
		)
	var mouse_button := event as InputEventMouseButton
	if mouse_button and mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
		card._stop_drag()
