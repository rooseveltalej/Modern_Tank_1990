extends Marker2D

class_name EnemyShootingSystem

@export var bullet_speed: float = 100
@export var min_shoot_interval:float = 2.0
@export var max_shoot_interval: float = 4.0

@onready var shoot_timer: Timer = $ShootTimer

const BULLET_SCENE = preload("res://Scenes/bullet.tscn")

var can_shoot = true

func _ready() -> void:
	shoot_timer.wait_time = randf_range(min_shoot_interval, max_shoot_interval)
	shoot_timer.start()

func disable():
	shoot_timer.process_mode = Node.PROCESS_MODE_DISABLED

func _on_shoot_timer_timeout() -> void:
	if !can_shoot:
		return
	can_shoot = false
	
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = get_parent().movement_direction
	
	bullet.speed = bullet_speed
	
	bullet.set_collision_mask_value(4, false)
	bullet.set_collision_mask_value(1, true)
	get_tree().root.add_child(bullet)
	bullet.tree_exited.connect(func(): can_shoot = true)
	
	
	
	
	
	
	
	
		
	
