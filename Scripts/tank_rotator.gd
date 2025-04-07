extends Node

class_name TankRotator

var parent_node: Node2D
func _ready() -> void:
	parent_node = get_parent()
	

func update_tank_rotation(current_direction: Vector2) -> void:
	if parent_node is not Node2D:
		return
	
	if current_direction == Vector2.RIGHT:
		parent_node.rotation = PI/2
	elif current_direction == Vector2.DOWN:
		parent_node.rotation = PI
	elif  current_direction == Vector2.LEFT:
		parent_node.rotation = -PI/2
	elif current_direction == Vector2.UP:
		parent_node.rotation = 0
