extends Node


var ui: UI
@export 
var player_lives: int = 3

# Nueva variable para modo multijugador
var is_multiplayer: bool = false

@export_group("Tank points")
@export var small_tank_points = 100
@export var fast_tank_points = 200
@export var big_tank_points = 300
@export var armored_tank_points = 400
@export_group("")

var small_tank_destroyed: int = 0
var fast_tank_destroyed: int = 0
var big_tank_destroyed: int = 0
var armored_tank_destroyed: int = 0

var stage_number: int = 1
var player_score: int = 0
var total_enemies_destroyed: int = 0
var enemies_per_level: int = 20

# Señales para comunicar eventos importantes
signal player_died
signal eagle_destroyed
signal level_completed
signal game_over

func _ready():
	print("GameManager ready!")
	# Conectar a las señales para detectar game over
	player_died.connect(_on_player_died)
	eagle_destroyed.connect(_on_eagle_destroyed)
	level_completed.connect(_on_level_completed)
	game_over.connect(_on_game_over)

func decrease_player_lives():
	player_lives -= 1
	print("Player lives decreased to: ", player_lives)
	if player_lives > 0:
		if ui:
			ui.update_player_lives(player_lives)
		player_died.emit()
	else:
		# Game Over - sin vidas
		if ui:
			ui.update_player_lives(player_lives)
		print("Triggering game over - no lives left")
		game_over.emit()

func enemy_destroyed(tank_type: String = "Basic"):
	if ui:
		ui.decrease_enemy_display()
	total_enemies_destroyed += 1
	
	# Añadir puntos según el tipo de tanque
	match tank_type:
		"Basic":
			small_tank_destroyed += 1
			player_score += small_tank_points
		"Fast":
			fast_tank_destroyed += 1
			player_score += fast_tank_points
		"Power":
			big_tank_destroyed += 1
			player_score += big_tank_points
		"Armor":
			armored_tank_destroyed += 1
			player_score += armored_tank_points
		_:
			# Valor por defecto si no coincide
			small_tank_destroyed += 1
			player_score += small_tank_points
	
	# Actualizar UI de puntuación si existe
	if ui and ui.has_method("update_score"):
		ui.update_score(player_score)
	
	print("Enemy destroyed: ", tank_type, ". Total: ", total_enemies_destroyed, "/", enemies_per_level, ". Score: ", player_score)
	
	# Verificar si se completó el nivel
	if total_enemies_destroyed >= enemies_per_level:
		level_completed.emit()

func eagle_was_destroyed():
	eagle_destroyed.emit()

func _on_player_died():
	print("Player died, lives remaining: ", player_lives)

func _on_eagle_destroyed():
	print("Eagle destroyed - Game Over")
	get_node("/root/SceneManager").show_game_over()

func _on_level_completed():
	print("Level completed!")
	get_node("/root/SceneManager").show_victory()

func _on_game_over():
	print("Game Over - No lives remaining")
	get_node("/root/SceneManager").show_game_over()

func reset_level_stats():
	total_enemies_destroyed = 0

func reset_game_stats():
	player_lives = 3
	player_score = 0
	stage_number = 1
	small_tank_destroyed = 0
	fast_tank_destroyed = 0
	big_tank_destroyed = 0
	armored_tank_destroyed = 0
	total_enemies_destroyed = 0
	is_multiplayer = false
	print("Game stats reset")
