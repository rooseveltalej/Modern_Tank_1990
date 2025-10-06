extends Control

@onready var pause_label: Label = %PauseLabel
@onready var resume_button: Button = %ResumeButton
@onready var menu_button: Button = %MenuButton

func _ready():
	# Conectar señales
	resume_button.pressed.connect(_on_resume_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Configurar foco inicial
	resume_button.grab_focus()
	
	# Ocultar por defecto
	visible = false

func show_pause_menu():
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()

func hide_pause_menu():
	visible = false
	get_tree().paused = false

func _on_resume_button_pressed():
	hide_pause_menu()

func _on_menu_button_pressed():
	hide_pause_menu()
	get_node("/root/SceneManager").show_main_menu()

# Manejar input de pausa
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC por defecto
		if visible:
			hide_pause_menu()
		else:
			show_pause_menu()
	
	if visible and event.is_action_pressed("ui_accept"):
		if resume_button.has_focus():
			_on_resume_button_pressed()
		elif menu_button.has_focus():
			_on_menu_button_pressed()