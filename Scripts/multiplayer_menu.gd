extends Control

@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var room_code_input: LineEdit = %RoomCodeInput
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton

var room_code: String = ""

func _ready():
	# Conectar señales
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Conectar señales del NetworkManager
	NetworkManager.connection_established.connect(_on_connection_established)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	# Configurar foco inicial
	host_button.grab_focus()
	
	# Generar código de sala aleatorio
	_generate_room_code()

func _generate_room_code():
	var code = ""
	for i in 4:
		code += str(randi() % 10)
	room_code_input.text = code

func _on_host_button_pressed():
	status_label.text = "Conectando al servidor..."
	room_code = room_code_input.text
	
	# Configurar como host
	NetworkManager.is_host = true
	NetworkManager.player_id = 1
	
	# Conectar al servidor
	if NetworkManager.connect_to_server():
		host_button.disabled = true
		join_button.disabled = true
	else:
		status_label.text = "Error: No se pudo conectar al servidor"

func _on_join_button_pressed():
	if room_code_input.text.length() < 4:
		status_label.text = "Ingresa un código de sala válido"
		return
	
	status_label.text = "Conectando al servidor..."
	room_code = room_code_input.text
	
	# Configurar como cliente
	NetworkManager.is_host = false
	NetworkManager.player_id = 2
	
	# Conectar al servidor
	if NetworkManager.connect_to_server():
		host_button.disabled = true
		join_button.disabled = true
	else:
		status_label.text = "Error: No se pudo conectar al servidor"

func _on_connection_established():
	status_label.text = "Conectado! Uniéndose a sala " + room_code + "..."
	
	# Unirse a la sala
	if NetworkManager.join_room(room_code):
		# Esperar un momento y luego iniciar el juego
		await get_tree().create_timer(1.0).timeout
		status_label.text = "¡Iniciando juego multijugador!"
		await get_tree().create_timer(1.0).timeout
		
		# Cambiar a la escena multijugador
		SceneManager.start_multiplayer_game()
	else:
		status_label.text = "Error: No se pudo unir a la sala"

func _on_connection_failed():
	status_label.text = "Error: Falló la conexión al servidor"
	host_button.disabled = false
	join_button.disabled = false

func _on_back_button_pressed():
	# Desconectar si está conectado
	if NetworkManager.is_connected:
		NetworkManager.disconnect_from_server()
	
	SceneManager.show_main_menu()

# Navegación con teclado
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if host_button.has_focus():
			_on_host_button_pressed()
		elif join_button.has_focus():
			_on_join_button_pressed()
		elif back_button.has_focus():
			_on_back_button_pressed()