extends Control

@onready var game_over_label: Label = %GameOverLabel
@onready var score_label: Label = %ScoreLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

func _ready():
	# Conectar señales
	restart_button.pressed.connect(_on_restart_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Mostrar puntuación final
	var game_manager = get_node("/root/GameManager")
	score_label.text = "PUNTUACIÓN FINAL: " + str(game_manager.player_score)
	
	# Configurar foco inicial
	restart_button.grab_focus()

func _on_restart_button_pressed():
	get_node("/root/SceneManager").restart_game()

func _on_menu_button_pressed():
	get_node("/root/SceneManager").show_main_menu()

# Navegación con teclado
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if restart_button.has_focus():
			_on_restart_button_pressed()
		elif menu_button.has_focus():
			_on_menu_button_pressed()