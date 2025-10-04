extends Marker2D

class_name ShootingSystem

var can_shoot = true

const BULLET_SCENE = preload("res://Scenes/bullet.tscn")

# Variables para multijugador
var is_multiplayer: bool = false
var is_local_player: bool = true

func _input(event: InputEvent) -> void:
	# Solo procesar disparo si es el jugador local o no es multijugador
	if is_multiplayer and !is_local_player:
		return
		
	if Input.is_action_just_pressed("shoot") and can_shoot:
		spawn_projectile()
		can_shoot = false

func spawn_projectile() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	if get_parent().previous_direction != Vector2.ZERO:
		bullet.direction = get_parent().previous_direction
	
	bullet.speed = 100
	
	# Configurar propiedades de multijugador
	if is_multiplayer:
		bullet.is_multiplayer = true
		bullet.is_from_player = is_local_player
		if get_parent().has_method("get") and get_parent().player_id:
			bullet.owner_id = get_parent().player_id
	
	# En multijugador, agregar a contenedor específico
	if is_multiplayer:
		var bullets_container = get_tree().get_first_node_in_group("multiplayer_bullets")
		if bullets_container:
			bullets_container.add_child(bullet)
		else:
			get_tree().root.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
	
	bullet.bullet_destroyed.connect(func(): can_shoot = true)

func create_remote_bullet(bullet_data: Dictionary):
	# Crear bala desde datos recibidos por red
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = Vector2(bullet_data.position.x, bullet_data.position.y)
	bullet.direction = Vector2(bullet_data.direction.x, bullet_data.direction.y)
	bullet.speed = 100
	bullet.is_from_player = bullet_data.is_from_player
	
	# Agregar al contenedor de balas multijugador
	var bullets_container = get_tree().get_first_node_in_group("multiplayer_bullets")
	if bullets_container:
		bullets_container.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
