extends Area2D


const TILE_SIZE = 8
@export var speed: float = 25.0
@export var enable_snapping: bool = true
@onready var tank_rotator: TankRotator = $TankRotator

@onready var sprite_2d: Sprite2D = $Sprite2D

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
	print_debug(front_raycasts)


func _physics_process(delta: float) -> void:
	var input_vector = get_input()
	
	if input_vector == Vector2.ZERO:
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
