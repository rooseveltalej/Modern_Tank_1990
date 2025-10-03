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
	var small_label = Label.new()
	small_label.theme_override_fonts = score_label.theme_override_fonts
	small_label.theme_override_font_sizes = score_label.theme_override_font_sizes
	small_label.theme_override_colors = score_label.theme_override_colors
	small_label.text = "Tanques básicos: " + str(game_manager.small_tank_destroyed) + " x " + str(game_manager.small_tank_points)
	small_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(small_label)
	
	var fast_label = Label.new()
	fast_label.theme_override_fonts = score_label.theme_override_fonts
	fast_label.theme_override_font_sizes = score_label.theme_override_font_sizes
	fast_label.theme_override_colors = score_label.theme_override_colors
	fast_label.text = "Tanques rápidos: " + str(game_manager.fast_tank_destroyed) + " x " + str(game_manager.fast_tank_points)
	fast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(fast_label)
	
	var big_label = Label.new()
	big_label.theme_override_fonts = score_label.theme_override_fonts
	big_label.theme_override_font_sizes = score_label.theme_override_font_sizes
	big_label.theme_override_colors = score_label.theme_override_colors
	big_label.text = "Tanques de poder: " + str(game_manager.big_tank_destroyed) + " x " + str(game_manager.big_tank_points)
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(big_label)
	
	var armored_label = Label.new()
	armored_label.theme_override_fonts = score_label.theme_override_fonts
	armored_label.theme_override_font_sizes = score_label.theme_override_font_sizes
	armored_label.theme_override_colors = score_label.theme_override_colors
	armored_label.text = "Tanques blindados: " + str(game_manager.armored_tank_destroyed) + " x " + str(game_manager.armored_tank_points)
	armored_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(armored_label)

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