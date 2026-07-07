class_name NetworkManager
extends Node

signal connected(peer_id: int)
signal disconnected(peer_id: int)
signal connection_failed
signal remote_ready(board_payload: Array, battle_seed: int)
signal shop_seed_received(shop_seed: int)
signal booster_rewards_received(request_id: int, reward_payload: Array)
signal purchase_validated(request_id: int, valid: bool)
signal player_name_received(player_name: String)

const SERVER_PEER_ID := 1
const MAX_CLIENTS := 1

var peer := ENetMultiplayerPeer.new()
var remote_peer_id := 0
var local_player_name := "Player"
var remote_player_name := "Enemy"
var _remote_shop_random := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("network_managers")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host(port: int) -> Error:
	disconnect_peer()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	connected.emit(multiplayer.get_unique_id())
	return OK


func join(ip: String, port: int) -> Error:
	disconnect_peer()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func disconnect_peer() -> void:
	remote_peer_id = 0
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


func send_ready(board_payload: Array[BattleBoardCardSnapshot], battle_seed: int) -> bool:
	var target_peer_id := _get_target_peer_id()
	if target_peer_id == 0:
		return false
	_receive_ready.rpc_id(target_peer_id, BattleBoardSnapshot.to_rpc_payload(board_payload), battle_seed)
	return true


func send_shop_seed(shop_seed: int) -> bool:
	var target_peer_id := _get_target_peer_id()
	if target_peer_id == 0:
		return false
	if is_host():
		_remote_shop_random.seed = shop_seed
	_receive_shop_seed.rpc_id(target_peer_id, shop_seed)
	return true


func request_booster_rewards(request_id: int, pack_data_path: String, reward_count: int, price: int) -> bool:
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		return false
	_receive_booster_reward_request.rpc_id(SERVER_PEER_ID, request_id, pack_data_path, reward_count, price)
	return true


func request_card_purchase_validation(request_id: int, offer_data_path: String, card_data_path: String, price: int) -> bool:
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		return false
	_receive_card_purchase_validation_request.rpc_id(SERVER_PEER_ID, request_id, offer_data_path, card_data_path, price)
	return true


func set_player_name(player_name: String) -> void:
	local_player_name = player_name.strip_edges()
	if local_player_name.is_empty():
		local_player_name = "Player"


func send_player_name() -> bool:
	var target_peer_id := _get_target_peer_id()
	if target_peer_id == 0:
		return false
	_receive_player_name.rpc_id(target_peer_id, local_player_name)
	return true


func is_connected_to_peer() -> bool:
	return _get_target_peer_id() != 0


func is_host() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()


func _get_target_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 0
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return 0
	if multiplayer.is_server():
		return remote_peer_id
	return SERVER_PEER_ID


@rpc("any_peer", "reliable")
func _receive_ready(board_payload: Array, battle_seed: int) -> void:
	remote_ready.emit(BattleBoardSnapshot.from_network_payload(board_payload).to_network_payload(), battle_seed)


@rpc("any_peer", "reliable")
func _receive_shop_seed(shop_seed: int) -> void:
	shop_seed_received.emit(shop_seed)


@rpc("any_peer", "reliable")
func _receive_booster_reward_request(request_id: int, pack_data_path: String, reward_count: int, price: int) -> void:
	if not multiplayer.is_server():
		return
	var pack_data: BoosterPackData = load(pack_data_path) as BoosterPackData
	if not pack_data or pack_data.price != price or pack_data.reward_count != reward_count:
		_send_booster_rewards.rpc_id(multiplayer.get_remote_sender_id(), request_id, [])
		return
	var rewards: Array[CardData] = pack_data.pick_rewards(reward_count, _remote_shop_random)
	var reward_payload: Array[String] = []
	for card in rewards:
		if card and not card.resource_path.is_empty():
			reward_payload.append(card.resource_path)
	_send_booster_rewards.rpc_id(multiplayer.get_remote_sender_id(), request_id, reward_payload)


@rpc("any_peer", "reliable")
func _receive_card_purchase_validation_request(request_id: int, offer_data_path: String, card_data_path: String, price: int) -> void:
	if not multiplayer.is_server():
		return
	var valid: bool = _is_valid_card_purchase(offer_data_path, card_data_path, price)
	_send_purchase_validation.rpc_id(multiplayer.get_remote_sender_id(), request_id, valid)


@rpc("authority", "reliable")
func _send_booster_rewards(request_id: int, reward_payload: Array) -> void:
	booster_rewards_received.emit(request_id, reward_payload)


@rpc("authority", "reliable")
func _send_purchase_validation(request_id: int, valid: bool) -> void:
	purchase_validated.emit(request_id, valid)


@rpc("any_peer", "reliable")
func _receive_player_name(player_name: String) -> void:
	remote_player_name = player_name.strip_edges()
	if remote_player_name.is_empty():
		remote_player_name = "Enemy"
	player_name_received.emit(remote_player_name)


func _on_peer_connected(peer_id: int) -> void:
	remote_peer_id = peer_id
	connected.emit(peer_id)
	send_player_name()


func _on_peer_disconnected(peer_id: int) -> void:
	if remote_peer_id == peer_id:
		remote_peer_id = 0
	disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	remote_peer_id = SERVER_PEER_ID
	connected.emit(SERVER_PEER_ID)
	send_player_name()


func _on_connection_failed() -> void:
	disconnect_peer()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	remote_peer_id = 0
	disconnected.emit(SERVER_PEER_ID)


func _is_valid_card_purchase(offer_data_path: String, card_data_path: String, price: int) -> bool:
	var offer_data: CardShopOfferData = load(offer_data_path) as CardShopOfferData
	var card_data: CardData = load(card_data_path) as CardData
	if not offer_data or not card_data:
		return false
	var catalog: CardCatalog = offer_data.card_catalog as CardCatalog
	if not catalog:
		return false
	if offer_data.get_price(card_data.rarity) != price:
		return false
	for resource in catalog.cards:
		var catalog_card: CardData = resource as CardData
		if catalog_card and catalog_card.resource_path == card_data.resource_path:
			return true
	return false
