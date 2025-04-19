extends Area2D

class_name Eagle

signal game_over

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func change_to_flag():
	sprite_2d.region_rect = Rect2(49, 80, 16, 16)

func _on_area_entered(area: Area2D) -> void:
	if area is Bullet or area is Enemy:
		change_to_flag()
		print_debug("LOST")
		game_over.emit()

		collision_shape_2d.set_deferred("disabled", true)
	if area is Bullet:
		area.queue_free()
