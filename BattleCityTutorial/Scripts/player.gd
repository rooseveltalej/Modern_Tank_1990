extends Area2D

class_name Player

@onready var player_respawn_point: Marker2D = get_respawn_point()
@onready var invincibility_system: InvincibilitySystem = $InvincibilitySystem

var current_speed = 0
const TILE_SIZE = 8
@export var speed: float = 25.0
@export var enable_snapping: bool = true
@onready var tank_rotator: TankRotator = $TankRotator
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var color: Color = Color.GOLD

# Variables para multijugador
var is_multiplayer: bool = false
var is_local_player: bool = true
var player_id: int = 1
var last_sent_position: Vector2
var last_sent_rotation: float

# Señales para multijugador
signal position_changed(position: Vector2, rotation: float)
signal bullet_fired(bullet_data: Dictionary)


@onready var front_raycasts: Array[RayCast2D] = [
	$RayCasts/Front/CenterRayCast,
	$RayCasts/Front/LeftRayCast,
	$RayCasts/Front/RightRayCast
]

@onready var right_raycasts: Array[RayCast2D] = [
	$RayCasts/Right/RightSideEndRayCast,
	$RayCasts/Right/RightSideStartRayCast
]

@onready var left_raycasts: Array[RayCast2D] = [
	$RayCasts/Left/LeftSideEndRayCast,
	$RayCasts/Left/LeftSideStartRayCast
]

var velocity = Vector2.ZERO
var previous_direction = Vector2.ZERO

var is_invincible:
	get:
		return invincibility_system.is_invincible

func _ready() -> void:
	animated_sprite_2d.modulate = color
	
	# Inicializar variables de multijugador
	last_sent_position = position
	last_sent_rotation = rotation
	
	respawn()

func get_respawn_point() -> Marker2D:
	# Intentar encontrar el punto de respawn correcto según el contexto
	var parent = get_parent()
	
	# Para modo multijugador
	if is_multiplayer:
		if is_local_player:
			# Jugador local usa Player1RespawnPoint
			var player1_respawn = parent.get_node_or_null("Player1RespawnPoint")
			if player1_respawn:
				return player1_respawn
		else:
			# Jugador remoto usa Player2RespawnPoint
			var player2_respawn = parent.get_node_or_null("Player2RespawnPoint")
			if player2_respawn:
				return player2_respawn
	
	# Para modo single player o fallback
	var single_respawn = parent.get_node_or_null("PlayerRespawnPoint")
	if single_respawn:
		return single_respawn
	
	# Fallback: usar la posición actual del jugador
	var fallback_marker = Marker2D.new()
	fallback_marker.global_position = global_position
	parent.add_child.call_deferred(fallback_marker)
	return fallback_marker


func _physics_process(delta: float) -> void:
	# Solo procesar input si es el jugador local
	if is_multiplayer and !is_local_player:
		return
	
	var input_vector = get_input()
	
	if input_vector == Vector2.ZERO:
		animated_sprite_2d.set_frame_and_progress(0,0)
		return
	
	tank_rotator.update_tank_rotation(input_vector)
	
	var is_front_colliding = front_raycasts.any(is_raycast_collding)
	
	if is_front_colliding:
		return

	velocity = input_vector * current_speed * delta
	
	position += velocity
	
	previous_direction = input_vector
	
	# Enviar posición en multijugador
	if is_multiplayer and is_local_player:
		send_position_update()
	
	if enable_snapping:
		var is_left_side_colliding = left_raycasts.any(is_raycast_collding)
		var is_right_side_colliding = right_raycasts.any(is_raycast_collding)
		apply_snapping(input_vector, is_front_colliding, is_left_side_colliding or is_right_side_colliding)


func get_input() -> Vector2:
	# Solo procesar input si es el jugador local
	if is_multiplayer and !is_local_player:
		return Vector2.ZERO

	if Input.is_action_pressed("right"):
		return Vector2.RIGHT
	if Input.is_action_pressed("left"):
		return Vector2.LEFT
	if Input.is_action_pressed("down"):
		return Vector2.DOWN
	if Input.is_action_pressed("up"):
		return Vector2.UP
	
	return Vector2.ZERO

func apply_snapping(input_vector: Vector2, is_front_colliding: bool, is_side_colliding: bool):
	await get_tree().process_frame
	
	if input_vector.y != 0 && !is_front_colliding && is_side_colliding:
		position = position.snapped(Vector2(TILE_SIZE, 0))
	elif input_vector.x != 0 && !is_front_colliding && is_side_colliding:
		position = position.snapped( Vector2(0,TILE_SIZE ))

func is_raycast_collding(raycast: RayCast2D):
	return raycast.is_colliding()

func respawn():
	# Verificar que tenemos un punto de respawn válido
	if not player_respawn_point:
		player_respawn_point = get_respawn_point()
	
	if player_respawn_point:
		global_position = player_respawn_point.global_position
	else:
		# Fallback: mantener posición actual
		print("Warning: No respawn point found for player")
	
	current_speed = speed
	set_physics_process(true)
	set_process_input(true)
	animated_sprite_2d.scale = Vector2(1, 1)
	animated_sprite_2d.play("default")
	invincibility_system.start_invincibility()

func explode():
	current_speed = 0
	set_physics_process(false)
	set_process_input(false)
	animated_sprite_2d.scale = Vector2(0.25, 0.25)
	animated_sprite_2d.play("explode")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "explode":
		GameManager.decrease_player_lives()
		if GameManager.player_lives > 0:
			respawn()
		else: 
			# END THE GAME - Game Over será manejado por GameManager
			queue_free()
		

func _on_area_entered(area: Area2D) -> void:
	if (area is Enemy && !is_invincible):
		explode()

# Funciones para multijugador
func send_position_update():
	if position.distance_to(last_sent_position) > 1.0 or abs(rotation - last_sent_rotation) > 0.1:
		last_sent_position = position
		last_sent_rotation = rotation
		print("Enviando posición: ", position, " rotación: ", rotation, " player_id: ", player_id)
		position_changed.emit(position, rotation)

func update_remote_position(new_position: Vector2, new_rotation: float):
	# Actualizar posición del jugador remoto suavemente
	print("Actualizando posición remota de ", player_id, " a: ", new_position, " rotación: ", new_rotation)
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", new_position, 0.1)
	tween.parallel().tween_property(self, "rotation", new_rotation, 0.1)

func fire_bullet():
	# Solo disparar si es el jugador local
	if is_multiplayer and !is_local_player:
		return
		
	# Obtener datos de la bala
	var bullet_data = {
		"position": {"x": position.x, "y": position.y},
		"rotation": rotation,
		"direction": {"x": previous_direction.x, "y": previous_direction.y},
		"is_from_player": true,
		"player_id": player_id
	}
	
	# Emitir señal para crear bala local y enviar por red
	bullet_fired.emit(bullet_data)

func _input(event):
	# Solo procesar disparo si es el jugador local
	if is_multiplayer and !is_local_player:
		return
		
	if event.is_action_pressed("shoot"):
		fire_bullet()
