extends Node2D


func _ready() -> void:
	if OS.is_debug_build():
		var debug_card_menu := load("res://game/debug/card_menu/debug_card_menu.tscn") as PackedScene
		add_child(debug_card_menu.instantiate())
