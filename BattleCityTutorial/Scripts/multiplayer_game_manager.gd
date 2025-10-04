extends Node

# Referencias a los jugadores
@onready var local_player = $LocalPlayer
@onready var remote_player = $RemotePlayer
@onready var camera = $Camera2D
@onready var ui = $UI
@onready var bullets_container = $MultiplayerBullets
@onready var network_players = $NetworkPlayers

var is_host: bool = false
var room_code: String = ""
var player_id: int = 1

func _ready():
	# Configurar NetworkManager callbacks
	NetworkManager.player_connected.connect(_on_player_joined)
	NetworkManager.player_disconnected.connect(_on_player_left)
	NetworkManager.game_data_received.connect(_on_game_data_received)
	
	# Obtener información de la sesión multijugador
	is_host = NetworkManager.is_host
	room_code = NetworkManager.room_code
	player_id = NetworkManager.player_id
	
	# Configurar jugadores
	setup_players()
	
	# Configurar cámara
	camera.make_current()

func setup_players():
	# Configurar jugador local
	local_player.is_multiplayer = true
	local_player.is_local_player = true
	local_player.player_id = player_id
	
	# Configurar shooting system del jugador local
	var local_shooting_system = local_player.get_node_or_null("ShootingSystem")
	if local_shooting_system:
		local_shooting_system.is_multiplayer = true
		local_shooting_system.is_local_player = true
	
	# Configurar jugador remoto
	remote_player.is_multiplayer = true
	remote_player.is_local_player = false
	remote_player.visible = false  # Ocultar hasta que se conecte otro jugador
	
	# Configurar shooting system del jugador remoto
	var remote_shooting_system = remote_player.get_node_or_null("ShootingSystem")
	if remote_shooting_system:
		remote_shooting_system.is_multiplayer = true
		remote_shooting_system.is_local_player = false
	
	# Conectar señales del jugador local
	local_player.position_changed.connect(_on_local_player_position_changed)
	local_player.bullet_fired.connect(_on_local_player_bullet_fired)

func _on_player_joined(player_id_received: int):
	print("Jugador conectado: ", player_id_received)
	print("Mi player_id: ", player_id)
	
	# Mostrar jugador remoto
	if player_id_received != player_id:
		remote_player.visible = true
		remote_player.player_id = player_id_received
		print("Mostrando jugador remoto con ID: ", player_id_received)
		
		# Actualizar UI
		ui.show_multiplayer_info(true, str(player_id_received))
	else:
		print("Ignorando mi propio join")

func _on_player_left(player_id_received: int):
	print("Jugador desconectado: ", player_id_received)
	
	# Ocultar jugador remoto
	if player_id_received != player_id:
		remote_player.visible = false
		
		# Actualizar UI
		ui.show_multiplayer_info(false, "")

func _on_game_data_received(data: Dictionary):
	# Procesar diferentes tipos de datos de juego
	print("Datos recibidos: ", data)
	
	if data.has("type"):
		match data.type:
			"player_position":
				_on_position_received(data)
			"position":
				_on_position_received(data)
			"bullet":
				_on_bullet_fired(data)
			"player_shoot":
				_on_bullet_fired(data)
			"tile_destroyed":
				_on_tile_destroyed(data)
			"game_state":
				_on_game_state_updated(data)
			_:
				print("Tipo de dato desconocido: ", data.type)

func _on_local_player_position_changed(position: Vector2, rotation: float):
	# Enviar posición al servidor
	NetworkManager.send_player_position(position, rotation)

func _on_local_player_bullet_fired(bullet_data: Dictionary):
	# Enviar información de bala al servidor
	if bullet_data.has("position") and bullet_data.has("direction"):
		var pos = Vector2(bullet_data.position.x, bullet_data.position.y)
		var dir = Vector2(bullet_data.direction.x, bullet_data.direction.y)
		NetworkManager.send_player_shoot(pos, dir)

func _on_position_received(player_data: Dictionary):
	# Actualizar posición del jugador remoto
	print("Procesando posición: ", player_data)
	
	if player_data.has("player_id") and player_data.player_id != player_id:
		if not remote_player.visible:
			remote_player.visible = true
			
		if player_data.has("x") and player_data.has("y") and player_data.has("rotation"):
			var new_position = Vector2(player_data.x, player_data.y)
			remote_player.update_remote_position(new_position, player_data.rotation)
			print("Actualizando posición remota a: ", new_position, " rotación: ", player_data.rotation)

func _on_bullet_fired(bullet_data: Dictionary):
	# Crear bala de jugador remoto
	if bullet_data.has("player_id") and bullet_data.player_id != player_id:
		create_remote_bullet(bullet_data)

func create_remote_bullet(bullet_data: Dictionary):
	# Crear bala desde el jugador remoto
	var bullet_scene = preload("res://Scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	
	bullet.position = Vector2(bullet_data.position.x, bullet_data.position.y)
	bullet.rotation = bullet_data.rotation
	bullet.direction = Vector2(bullet_data.direction.x, bullet_data.direction.y)
	bullet.is_from_player = bullet_data.is_from_player
	bullet.is_multiplayer = true
	bullet.owner_id = bullet_data.player_id
	
	bullets_container.add_child(bullet)

func _on_game_state_updated(game_data: Dictionary):
	# Actualizar estado del juego
	print("Estado del juego actualizado: ", game_data)
	
	# Actualizar vidas, puntuación, etc.
	if game_data.has("player_lives"):
		GameManager.player_lives = game_data.player_lives
	
	if game_data.has("score"):
		GameManager.score = game_data.score

func _on_tile_destroyed(tile_data: Dictionary):
	# Sincronizar destrucción de tiles entre jugadores
	if tile_data.has("tile_x") and tile_data.has("tile_y"):
		var tilemap_layer = get_tree().get_first_node_in_group("tilemap_layer")
		if tilemap_layer:
			var tile_pos = Vector2i(tile_data.tile_x, tile_data.tile_y)
			tilemap_layer.set_cell(tile_pos, -1, Vector2i(-1, -1))
			print("Tile destruido remotamente en: ", tile_pos)

func send_tile_destroyed(tile_x: int, tile_y: int):
	# Enviar destrucción de tile al servidor
	var tile_data = {
		"type": "tile_destroyed",
		"tile_x": tile_x,
		"tile_y": tile_y,
		"player_id": player_id
	}
	NetworkManager.send_data(tile_data)

func _on_eagle_destroyed():
	# Manejar destrucción del águila en multijugador
	print("Águila destruida en multijugador")
	GameManager.eagle_was_destroyed()

func _input(event):
	# Manejar pausa en multijugador
	if event.is_action_pressed("pause"):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			# Mostrar menú de pausa multijugador
			print("Juego pausado en multijugador")

func _exit_tree():
	# Limpiar cuando se sale de la escena
	if NetworkManager.is_connected:
		NetworkManager.disconnect_from_server()