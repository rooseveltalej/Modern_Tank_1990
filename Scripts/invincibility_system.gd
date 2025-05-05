extends Node2D

class_name InvincibilitySystem

@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var invincibility_animated_sprite: AnimatedSprite2D = $InvincibilityAnimatedSprite

var is_invincible:
	get:
		return !invincibility_timer.is_stopped()
	
func start_invincibility():
	invincibility_animated_sprite.show()
	invincibility_timer.start()
	invincibility_animated_sprite.play("default")
	


func _on_invincibility_timer_timeout() -> void:
	invincibility_animated_sprite.hide()
	invincibility_animated_sprite.stop()
