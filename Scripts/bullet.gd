extends Area2D

class_name Bullet

signal bullet_destroyed

@export var speed = 50

var direction = Vector2.UP

const LEFT_CORNER_POSITION = Vector2(-1.5, -2)
const RIGHT_CORNER_POSITION = Vector2(1.5, -2)


func _ready() -> void:

	if direction == Vector2.RIGHT:
		rotation = PI / 2
	elif direction == Vector2.DOWN:
		rotation = PI
	elif direction == Vector2.LEFT:
		rotation = - PI / 2
	else:
		rotation = 0

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		handle_tilemap_layer_collision(body)
		


func handle_tilemap_layer_collision(tile_map_layer: TileMapLayer):
	
	var left_collision_corner = global_position + LEFT_CORNER_POSITION.rotated(rotation)
	var right_collision_corner = global_position + RIGHT_CORNER_POSITION.rotated(rotation)
	
	check_bullet_collision_for_corner(left_collision_corner, tile_map_layer)
	check_bullet_collision_for_corner(right_collision_corner, tile_map_layer)
	
	bullet_destroyed.emit()
	queue_free()

func check_bullet_collision_for_corner(corner: Vector2, tile_map_layer: TileMapLayer):
	var tile_position = tile_map_layer.local_to_map(tile_map_layer.to_local(corner))
	var tile_data = tile_map_layer.get_cell_tile_data(tile_position)
	
	if tile_data == null || !tile_data.get_custom_data("can_be_destroyed"):
		return
	
	tile_map_layer.set_cell(tile_position, -1, Vector2i(-1, -1))
	


func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		(area as Enemy).hit()
		queue_free()
	if (area is Player):
		(area as Player).explode()
		queue_free()
