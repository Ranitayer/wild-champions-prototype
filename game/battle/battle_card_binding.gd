class_name BattleCardBinding
extends RefCounted

var visual: CardVisual
var slot: CardSlot


func _init(card_visual: CardVisual, card_slot: CardSlot) -> void:
	visual = card_visual
	slot = card_slot
