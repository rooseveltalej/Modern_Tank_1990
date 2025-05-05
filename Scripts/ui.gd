extends CanvasLayer

class_name UI

@onready var enemies_grid_container: GridContainer = %EnemiesGridContainer
@onready var player_lives_label: Label = %PlayerLivesLabel

const ENEMY_UI_TEXTURE = preload("res://Assets/enemy_ui_texture.tres")

const ENEMIES_PER_LEVEL = 20;

func _ready() -> void:
	for i in ENEMIES_PER_LEVEL:
		var texture_rect = TextureRect.new()
		texture_rect.texture = ENEMY_UI_TEXTURE
		texture_rect.custom_minimum_size = Vector2(48,48)
		enemies_grid_container.add_child(texture_rect)
	
	update_player_lives(GameManager.player_lives)
	GameManager.ui = self
	

func update_player_lives(player_lives: int) -> void:
	player_lives_label.text = str(player_lives)

func decrease_enemy_display() -> void:
	var last_child_in_grid_id = enemies_grid_container.get_child_count() -1 
	enemies_grid_container.remove_child(enemies_grid_container.get_child(last_child_in_grid_id))
