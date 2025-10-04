extends Control

@onready var start_button: Button = %StartButton
@onready var multiplayer_button: Button = %MultiplayerButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var title_label: Label = %TitleLabel

func _ready():
	# Conectar señales de los botones
	start_button.pressed.connect(_on_start_button_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Configurar foco inicial
	start_button.grab_focus()

func _on_start_button_pressed():
	get_node("/root/SceneManager").start_game()

func _on_multiplayer_button_pressed():
	get_node("/root/SceneManager").show_multiplayer_menu()

func _on_settings_button_pressed():
	# Por ahora solo imprime, puedes expandir para mostrar menú de configuraciones
	print("Configuraciones - Por implementar")

func _on_quit_button_pressed():
	get_node("/root/SceneManager").quit_game()

# Navegación con teclado
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if start_button.has_focus():
			_on_start_button_pressed()
		elif multiplayer_button.has_focus():
			_on_multiplayer_button_pressed()
		elif settings_button.has_focus():
			_on_settings_button_pressed()
		elif quit_button.has_focus():
			_on_quit_button_pressed()