extends Node

# Referencias a los jugadores
@onready var local_player = $LocalPlayer
@onready var remote_player = $RemotePlayer
@onready var camera = $Camera2D
@onready var ui = $UI
@onready var bullets_container = $MultiplayerBullets
@onready var network_players = $NetworkPlayers
@onready var enemy_spawner = $EnemySpawner

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
	
	# --- LÓGICA INTEGRADA PARA ENEMIGOS ---
	# Activa el generador de enemigos solo si este jugador es el Host.
	if is_host:
		print("Soy el host, activando spawner de enemigos.")
		# Llama a la función para que el spawner comience a funcionar.
		enemy_spawner.start_spawning()
	else:
		print("Soy un cliente, el spawner de enemigos está desactivado.")
		# Si no es el host, elimina el spawner para que no interfiera.
		enemy_spawner.queue_free()
	# ------------------------------------

	# Configurar jugadores
	setup_players()
	
	# Configurar cámara
	camera.make_current()

func setup_players():
	print("Configurando jugadores - Mi ID: ", player_id)
	
	# Configurar jugador local
	local_player.is_multiplayer = true
	local_player.is_local_player = true
	local_player.player_id = player_id
	print("Jugador local configurado - ID: ", local_player.player_id, " es_local: ", local_player.is_local_player)
	
	# Configurar shooting system del jugador local
	var local_shooting_system = local_player.get_node_or_null("ShootingSystem")
	if local_shooting_system:
		local_shooting_system.is_multiplayer = true
		local_shooting_system.is_local_player = true
	
	# Configurar jugador remoto
	remote_player.is_multiplayer = true
	remote_player.is_local_player = false
	remote_player.visible = false  # Ocultar hasta que se conecte otro jugador
	print("Jugador remoto configurado - es_local: ", remote_player.is_local_player, " visible: ", remote_player.visible)
	
	# Configurar shooting system del jugador remoto
	var remote_shooting_system = remote_player.get_node_or_null("ShootingSystem")
	if remote_shooting_system:
		remote_shooting_system.is_multiplayer = true
		remote_shooting_system.is_local_player = false
	
	# Conectar señales del jugador local
	local_player.position_changed.connect(_on_local_player_position_changed)
	local_player.bullet_fired.connect(_on_local_player_bullet_fired)
	print("Señales conectadas para jugador local")

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
			"player_shoot":
				_on_bullet_fired(data)
			"spawn_bullet":
				if data.has("data"):
					_on_bullet_fired(data.data)
				else:
					_on_bullet_fired(data)
			"tile_destroyed":
				_on_tile_destroyed(data)
			"game_state":
				_on_game_state_updated(data)
			
			# --- LÓGICA INTEGRADA PARA ENEMIGOS ---
			
			# Caso 1: Un nuevo enemigo es creado por el Host.
			"spawn_enemy":
				# Solo el cliente (quien no es el Host) debe crear el enemigo.
				if not is_host:
					_on_enemy_spawned(data)
			
			# Caso 2: El Host envía la nueva posición de un enemigo.
			"enemy_position":
				 # Solo el cliente debe actualizar la posición del enemigo.
				if not is_host:
					# Busca el enemigo por su nombre/ID único.
					var enemy_node = get_node_or_null(data.enemy_id)
					if enemy_node:
						# Actualiza su posición y rotación suavemente.
						enemy_node.global_position = Vector2(data.x, data.y)
						enemy_node.rotation = data.rotation
			# ------------------------------------
			
			_:
				print("Tipo de dato desconocido: ", data.type)

func _on_local_player_position_changed(position: Vector2, rotation: float):
	# Enviar posición al servidor
	print("Recibida señal de posición local: ", position, " rotación: ", rotation)
	NetworkManager.send_player_position(position, rotation)

func _on_local_player_bullet_fired(bullet_data: Dictionary):
	# Enviar información completa de la bala al servidor
	var data_to_send = bullet_data.duplicate()
	data_to_send["type"] = "player_shoot"
	NetworkManager.send_data(data_to_send)

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
	print("Creando bala remota con datos: ", bullet_data)
	
	var bullet_scene = preload("res://Scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	
	# Manejar diferentes formatos de posición
	var bullet_position: Vector2
	if bullet_data.has("position"):
		if typeof(bullet_data.position) == TYPE_VECTOR2:
			# Ya es Vector2
			bullet_position = bullet_data.position
		elif typeof(bullet_data.position) == TYPE_DICTIONARY:
			# Formato anidado: {"position": {"x": 0, "y": 0}}
			bullet_position = Vector2(bullet_data.position.x, bullet_data.position.y)
		else:
			print("Error: Tipo de posición no reconocido: ", typeof(bullet_data.position))
			return
	elif bullet_data.has("x") and bullet_data.has("y"):
		# Formato directo: {"x": 0, "y": 0}
		bullet_position = Vector2(bullet_data.x, bullet_data.y)
	else:
		print("Error: Formato de posición de bala no reconocido")
		return
	
	bullet.position = bullet_position
	
	# Manejar rotación
	if bullet_data.has("rotation"):
		bullet.rotation = bullet_data.rotation
	
	# Manejar dirección
	var bullet_direction: Vector2
	if bullet_data.has("direction"):
		if typeof(bullet_data.direction) == TYPE_VECTOR2:
			# Ya es Vector2
			bullet_direction = bullet_data.direction
		elif typeof(bullet_data.direction) == TYPE_DICTIONARY:
			bullet_direction = Vector2(bullet_data.direction.x, bullet_data.direction.y)
		else:
			print("Error: Tipo de dirección no reconocido: ", typeof(bullet_data.direction))
			return
	elif bullet_data.has("dir_x") and bullet_data.has("dir_y"):
		# Formato directo con dir_x, dir_y
		bullet_direction = Vector2(bullet_data.dir_x, bullet_data.dir_y)
	else:
		print("Error: Formato de dirección no reconocido")
		return
	
	bullet.direction = bullet_direction
	
	# Configurar propiedades
	bullet.is_from_player = bullet_data.get("is_from_player", true)
	bullet.is_multiplayer = true
	bullet.owner_id = bullet_data.get("player_id", 0)
	
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
		
func _on_enemy_spawned(enemy_data: Dictionary):
	print("Creando enemigo remoto: ", enemy_data.enemy_id)
	var enemy_scene = preload("res://Scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()

	enemy.name = enemy_data.enemy_id
	enemy.tank_type = load(enemy_data.tank_type_path)
	enemy.global_position = Vector2(enemy_data.position.x, enemy_data.position.y)

	# Desactivamos la IA en el cliente, solo seguirá las órdenes del host
	enemy.set_physics_process(false) 

	add_child(enemy)
