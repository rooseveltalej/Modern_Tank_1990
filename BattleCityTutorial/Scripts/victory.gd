extends Control

@onready var victory_label: Label = %VictoryLabel
@onready var score_label: Label = %ScoreLabel
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var continue_button: Button = %ContinueButton
@onready var menu_button: Button = %MenuButton

func _ready():
	# Conectar señales
	continue_button.pressed.connect(_on_continue_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Mostrar estadísticas
	display_victory_stats()
	
	# Configurar foco inicial
	continue_button.grab_focus()

func display_victory_stats():
	# Mostrar puntuación
	var game_manager = get_node("/root/GameManager")
	score_label.text = "PUNTUACIÓN: " + str(game_manager.player_score)
	
	# Crear labels para mostrar estadísticas de tanques destruidos
	create_stat_label("Tanques básicos: " + str(game_manager.small_tank_destroyed) + " x " + str(game_manager.small_tank_points))
	create_stat_label("Tanques rápidos: " + str(game_manager.fast_tank_destroyed) + " x " + str(game_manager.fast_tank_points))
	create_stat_label("Tanques de poder: " + str(game_manager.big_tank_destroyed) + " x " + str(game_manager.big_tank_points))
	create_stat_label("Tanques blindados: " + str(game_manager.armored_tank_destroyed) + " x " + str(game_manager.armored_tank_points))

func create_stat_label(text: String):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Aplicar el mismo estilo que score_label pero de forma segura
	var font_resource = preload("res://Assets/Font/Minecraft.ttf")
	label.add_theme_font_override("font", font_resource)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	 
	stats_container.add_child(label)

func _on_continue_button_pressed():
	# Incrementar nivel y continuar
	var game_manager = get_node("/root/GameManager")
	game_manager.stage_number += 1
	get_node("/root/SceneManager").start_game()

func _on_menu_button_pressed():
	get_node("/root/SceneManager").show_main_menu()

# Navegación con teclado
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if continue_button.has_focus():
			_on_continue_button_pressed()
		elif menu_button.has_focus():
			_on_menu_button_pressed()
