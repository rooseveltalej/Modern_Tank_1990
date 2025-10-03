extends Area2D

class_name Enemy

@export var tank_type: TankType
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var tank_rotator: TankRotator = $TankRotator
@onready var enemy_shooting_system: EnemyShootingSystem = $EnemyShootingSystem

var is_spawned = false
var health: int = 1
var points = 100
var speed = 50
var movement_direction: Vector2 = Vector2.ZERO
var move_timer = 1.0
var move_duration = 1.0
var tile_map_layer: TileMapLayer

var directions = [
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT
]

func _ready() -> void:
	tile_map_layer = get_tree().get_first_node_in_group("tilemap_layer")
	speed = tank_type.speed
	health = tank_type.health
	points = tank_type.points
	enemy_shooting_system.bullet_speed = tank_type.bullet_speed
	enemy_shooting_system.min_shoot_interval = tank_type.min_shoot_interval
	enemy_shooting_system.max_shoot_interval = tank_type.max_shoot_interval
	set_random_direction()
	
func set_random_direction():
	movement_direction = directions.pick_random()
	
	while check_for_tile_in_direction(movement_direction):
		movement_direction = directions.pick_random()
	
	tank_rotator.update_tank_rotation(movement_direction)	

func _process(delta: float) -> void:
	if !is_spawned:
		return
	move_timer -= delta
	
	if move_timer <= 0:
		set_random_direction()
	move_timer = move_duration
	position += movement_direction * speed * delta
	
	if ray_cast_2d.is_colliding():
		set_random_direction()
		
		if movement_direction.x != 0:
			
			position = position.snapped(Vector2(0, 8))
		elif movement_direction.y != 0:
			position = position.snapped(Vector2(8, 0))

func check_for_tile_in_direction(movement_direction: Vector2) ->  bool:
	var position_to_check = global_position + movement_direction * 8.1
	
	var tile_position = tile_map_layer.local_to_map(tile_map_layer.to_local(position_to_check))
	var tile_data = tile_map_layer.get_cell_tile_data(tile_position)
	if tile_data:
		return true
	else: 
		return false
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "spawn":
		is_spawned = true
		animated_sprite_2d.scale = Vector2(1,1)
		animated_sprite_2d.play(tank_type.tank_name)
	if animated_sprite_2d.animation == "explosion":
		queue_free()

func hit():
	health -= 1
	if health == 0:
		explode()

func explode():
	enemy_shooting_system.disable()
	speed = 0
	collision_shape_2d.set_deferred("disabled", true)
	animated_sprite_2d.scale = Vector2(0.25, 0.25)
	animated_sprite_2d.play("explosion")
	
	# Notificar al GameManager que un enemigo fue destruido
	get_node("/root/GameManager").enemy_destroyed(tank_type.tank_name)
