extends CanvasLayer

class_name UI

@onready var enemies_grid_container: GridContainer = %EnemiesGridContainer
@onready var player_lives_label: Label = %PlayerLivesLabel
@onready var score_label: Label = %ScoreLabel

# Variables para multijugador
var multiplayer_info_label: Label
var is_multiplayer_mode: bool = false

const ENEMY_UI_TEXTURE = preload("res://Assets/enemy_ui_texture.tres")

const ENEMIES_PER_LEVEL = 20;

func _ready() -> void:
	for i in ENEMIES_PER_LEVEL:
		var texture_rect = TextureRect.new()
		texture_rect.texture = ENEMY_UI_TEXTURE
		texture_rect.custom_minimum_size = Vector2(48,48)
		enemies_grid_container.add_child(texture_rect)
	
	update_player_lives(GameManager.player_lives)
	update_score(GameManager.player_score)
	GameManager.ui = self
	
	# Crear label para información multijugador
	create_multiplayer_info_label()

func update_player_lives(player_lives: int) -> void:
	player_lives_label.text = str(player_lives)

func decrease_enemy_display() -> void:
	var last_child_in_grid_id = enemies_grid_container.get_child_count() -1 
	if last_child_in_grid_id >= 0:
		enemies_grid_container.remove_child(enemies_grid_container.get_child(last_child_in_grid_id))

func update_score(score: int) -> void:
	if score_label:
		score_label.text = "SCORE: " + str(score)

func create_multiplayer_info_label():
	# Crear label para mostrar información multijugador
	multiplayer_info_label = Label.new()
	multiplayer_info_label.text = "Esperando jugador..."
	multiplayer_info_label.position = Vector2(10, 100)
	multiplayer_info_label.visible = false
	add_child(multiplayer_info_label)

func show_multiplayer_info(player_connected: bool, player_name: String = ""):
	is_multiplayer_mode = true
	multiplayer_info_label.visible = true
	
	if player_connected:
		multiplayer_info_label.text = "Jugador conectado: " + player_name
		multiplayer_info_label.modulate = Color.GREEN
	else:
		multiplayer_info_label.text = "Esperando jugador..."
		multiplayer_info_label.modulate = Color.YELLOW

func hide_multiplayer_info():
	is_multiplayer_mode = false
	if multiplayer_info_label:
		multiplayer_info_label.visible = false
