class_name CardCollectionDragState
extends RefCounted

var entry: CardCollectionEntry
var ghost_id := 0


func _init(drag_entry: CardCollectionEntry = null, drag_ghost_id: int = 0) -> void:
	entry = drag_entry
	ghost_id = drag_ghost_id


func get_ghost() -> Control:
	return instance_from_id(ghost_id) as Control
