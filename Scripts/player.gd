extends Area2D

class_name Player

const TILE_SIZE = 8
@export var speed: float = 25.0
@export var enable_snapping: bool = true
@onready var tank_rotator: TankRotator = $TankRotator
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var color: Color = Color.GOLD


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

func _ready() -> void:
	animated_sprite_2d.modulate = color


func _physics_process(delta: float) -> void:
	var input_vector = get_input()
	
	if input_vector == Vector2.ZERO:
		animated_sprite_2d.set_frame_and_progress(0,0)
		return
	
	tank_rotator.update_tank_rotation(input_vector)
	
	var is_front_colliding = front_raycasts.any(is_raycast_collding)
	
	if is_front_colliding:
		return

	velocity = input_vector * speed * delta
	
	
	position += velocity
	
	previous_direction = input_vector
	
	if enable_snapping:
		var is_left_side_colliding = left_raycasts.any(is_raycast_collding)
		var is_right_side_colliding = right_raycasts.any(is_raycast_collding)
		apply_snapping(input_vector, is_front_colliding, is_left_side_colliding or is_right_side_colliding)


func get_input() -> Vector2:

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

func explode():
	speed = 0
	set_physics_process(false)
	set_process_input(false)
	animated_sprite_2d.scale = Vector2(0.25, 0.25)
	animated_sprite_2d.play("explode")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "explode":
		queue_free()
		

func _on_area_entered(area: Area2D) -> void:
	if (area is Enemy):
		explode()
