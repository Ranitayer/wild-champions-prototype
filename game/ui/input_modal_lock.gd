class_name InputModalLock
extends RefCounted


static func set_locked(tree: SceneTree, locked: bool) -> void:
	if not tree:
		return
	for node in tree.get_nodes_in_group("card_visuals"):
		var card: CardVisual = node as CardVisual
		if card:
			card.set_interaction_blocked(locked)
	for node in tree.get_nodes_in_group("shop_purchasables"):
		if node.has_method("set_payment_pending"):
			node.set_payment_pending(locked)
