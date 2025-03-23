extends Marker2D

class_name ShootingSystem

var can_shoot = true

const BULLET_SCENE = preload("res://Scenes/bullet.tscn")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("shoot"):
		spawn_projectile()
		can_shoot = false
		

func spawn_projectile() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	if get_parent().previous_direction != Vector2.ZERO:
		bullet.direction = get_parent().previous_direction
	
	get_tree().root.add_child(bullet)
	bullet.bullet_destroyed.connect(func(): can_shoot = true)
