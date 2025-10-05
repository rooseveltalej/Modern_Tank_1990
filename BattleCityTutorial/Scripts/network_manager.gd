extends Node

# NetworkManager - Autoload singleton para manejar conexiones multijugador

signal player_connected(player_id: int)
signal player_disconnected(player_id: int)
signal game_data_received(data: Dictionary)
signal connection_established
signal connection_failed

var websocket: WebSocketPeer
var is_connected: bool = false
var is_host: bool = false
var player_id: int = 1
var room_code: String = ""
var server_url: String = "wss://battlecity-relay-544519459817.us-central1.run.app"

# Estados del juego para sincronizar
var network_players: Dictionary = {}
var network_enemies: Dictionary = {}
var network_bullets: Dictionary = {}

func _ready():
	print("NetworkManager ready!")

func _process(_delta):
	if websocket:
		websocket.poll()
		var state = websocket.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			if not is_connected:
				is_connected = true
				connection_established.emit()
				print("Conectado al servidor!")
			
			# Procesar mensajes recibidos
			while websocket.get_available_packet_count():
				var packet = websocket.get_packet()
				var message = packet.get_string_from_utf8()
				_handle_message(message)
		
		elif state == WebSocketPeer.STATE_CLOSED:
			if is_connected:
				is_connected = false
				print("Conexión cerrada")

func connect_to_server():
	websocket = WebSocketPeer.new()
	var error = websocket.connect_to_url(server_url)
	if error != OK:
		print("Error conectando al servidor: ", error)
		connection_failed.emit()
		return false
	print("Intentando conectar a: ", server_url)
	return true

func join_room(room: String):
	if not is_connected:
		print("No conectado al servidor")
		return false
	
	room_code = room
	var join_data = {
		"type": "join",
		"room": room
	}
	send_data(join_data)
	return true

func send_data(data: Dictionary):
	if websocket and is_connected:
		var message = JSON.stringify(data)
		websocket.send_text(message)

func _handle_message(message: String):
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		print("Error parsing JSON: ", message)
		return
	
	var data = json.data
	print("Datos recibidos: ", data)
	
	match data.type:
		"player_position":
			_handle_player_position(data)
		"player_shoot":
			_handle_player_shoot(data)
		"enemy_position":
			_handle_enemy_position(data)
		"enemy_destroyed":
			_handle_enemy_destroyed(data)
		"game_state":
			_handle_game_state(data)
		_:
			game_data_received.emit(data)

func _handle_player_position(data: Dictionary):
	var remote_player_id = data.player_id
	if remote_player_id != player_id:
		network_players[remote_player_id] = {
			"position": Vector2(data.x, data.y),
			"rotation": data.rotation,
			"animation": data.get("animation", "default")
		}
		game_data_received.emit(data)

func _handle_player_shoot(data: Dictionary):
	var remote_player_id = data.player_id
	if remote_player_id != player_id:
		# Crear bala del jugador remoto
		var bullet_data = {
			"position": Vector2(data.x, data.y),
			"direction": Vector2(data.dir_x, data.dir_y),
			"player_id": remote_player_id
		}
		game_data_received.emit({"type": "spawn_bullet", "data": bullet_data})

func _handle_enemy_position(data: Dictionary):
	network_enemies[data.enemy_id] = {
		"position": Vector2(data.x, data.y),
		"rotation": data.rotation
	}

func _handle_enemy_destroyed(data: Dictionary):
	if data.enemy_id in network_enemies:
		network_enemies.erase(data.enemy_id)
	game_data_received.emit({"type": "enemy_destroyed", "enemy_id": data.enemy_id})

func _handle_game_state(data: Dictionary):
	game_data_received.emit({"type": "game_state", "data": data})

# Funciones para enviar datos del juego
func send_player_position(position: Vector2, rotation: float, animation: String = "default"):
	var data = {
		"type": "player_position",
		"player_id": player_id,
		"x": position.x,
		"y": position.y,
		"rotation": rotation,
		"animation": animation
	}
	send_data(data)

func send_player_shoot(position: Vector2, direction: Vector2):
	var data = {
		"type": "player_shoot",
		"player_id": player_id,
		"x": position.x,
		"y": position.y,
		"dir_x": direction.x,
		"dir_y": direction.y
	}
	send_data(data)

func send_enemy_position(enemy_id: String, position: Vector2, rotation: float):
	# Solo el host envía posiciones de enemigos
	if is_host:
		var data = {
			"type": "enemy_position",
			"enemy_id": enemy_id,
			"x": position.x,
			"y": position.y,
			"rotation": rotation
		}
		send_data(data)

func send_enemy_destroyed(enemy_id: String):
	if is_host:
		var data = {
			"type": "enemy_destroyed",
			"enemy_id": enemy_id
		}
		send_data(data)

func disconnect_from_server():
	if websocket:
		websocket.close()
	is_connected = false
	room_code = ""
	network_players.clear()
	network_enemies.clear()
	network_bullets.clear()