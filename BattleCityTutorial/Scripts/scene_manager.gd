extends Node

# Scene Manager - Autoload singleton para manejar transiciones entre escenas

signal scene_changed(scene_name: String)

var current_scene: Node = null

func _ready():
	print("SceneManager ready!")
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(path: String):
	print("Changing to scene: ", path)
	# Esta función cambia a una nueva escena
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path: String):
	# Libera la escena actual
	if current_scene:
		current_scene.free()
	
	# Carga la nueva escena
	var new_scene = ResourceLoader.load(path)
	if new_scene == null:
		print("Error: Could not load scene: ", path)
		return
	
	# Instancia la nueva escena
	current_scene = new_scene.instantiate()
	
	# Añade al árbol
	get_tree().root.add_child(current_scene)
	
	# Configura como escena actual
	get_tree().current_scene = current_scene
	
	# Emite señal de cambio
	scene_changed.emit(path.get_file().get_basename())

# Funciones específicas para cambiar escenas
func start_game():
	# Reiniciar estadísticas del nivel al empezar
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.reset_level_stats()
	goto_scene("res://Scenes/main.tscn")

func show_main_menu():
	goto_scene("res://Scenes/main_menu.tscn")

func show_game_over():
	goto_scene("res://Scenes/game_over.tscn")

func show_victory():
	goto_scene("res://Scenes/victory.tscn")

func restart_game():
	# Reinicia las variables del GameManager
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.reset_game_stats()
	start_game()

func quit_game():
	get_tree().quit()