extends Node2D

# --- CONSTANTES Y CONFIGURACIÓN ---
const ENEMY_SCENE = preload("res://Scenes/enemy.tscn")
const SPAWN_DELAY = 2.0 # Tiempo entre apariciones

# El orden en que aparecerán los tanques enemigos
const enemy_array = [
	"Armor", "Power", "Basic", "Basic", "Basic", "Basic", "Basic", "Basic",
	"Basic", "Basic", "Basic", "Fast", "Basic", "Basic", "Fast", "Power",
	"Fast", "Power", "Power", "Basic"
]

# --- REFERENCIAS A NODOS (OnReady Vars) ---

# Obtenemos el NODO padre que contiene todos los puntos de aparición.
# Esta es la forma correcta de hacerlo.
@onready var spawn_points_container: Node2D = $SpawnPoints
@onready var spawn_timer: Timer = $SpawnTimer

# Diccionario que asocia los nombres de los tanques con sus archivos de configuración
@onready var tank_types = {
	"Basic": preload("res://Resources/BasicTank.tres"),
	"Fast": preload("res://Resources/FastTank.tres"),
	"Power": preload("res://Resources/PowerTank.tres"),
	"Armor": preload("res://Resources/ArmorTank.tres")
}

# --- VARIABLES DE ESTADO ---
var enemy_spawn_index = 0 # Para saber qué enemigo del array toca crear

# --- FUNCIONES DEL MOTOR ---

func _ready() -> void:
	spawn_timer.wait_time = SPAWN_DELAY
	spawn_timer.timeout.connect(spawn_enemy)

# --- LÓGICA DEL SPAWNER ---

func start_spawning():
	# Reinicia el contador y arranca el temporizador para el primer enemigo.
	enemy_spawn_index = 0
	spawn_timer.start()

func spawn_enemy():
	# Si ya hemos creado todos los enemigos del array, nos detenemos.
	if enemy_spawn_index >= enemy_array.size():
		spawn_timer.stop()
		print("Todos los enemigos del nivel han sido generados.")
		return

	# 1. Obtiene el nombre del siguiente tanque a crear
	var tank_name_to_spawn = enemy_array[enemy_spawn_index]
	
	# 2. Elige un punto de aparición al azar de los hijos del nodo contenedor
	var spawn_point = spawn_points_container.get_children().pick_random()

	# 3. Crea la instancia del enemigo
	var enemy = ENEMY_SCENE.instantiate()
	
	# 4. Asigna el tipo de tanque correcto desde nuestro diccionario
	enemy.tank_type = tank_types[tank_name_to_spawn]
	
	# 5. Le damos un nombre único para la red
	var enemy_id = "enemy_" + str(Time.get_ticks_msec())
	enemy.name = enemy_id
	
	# 6. Añade el enemigo a la escena y lo posiciona
	add_child(enemy)
	enemy.global_position = spawn_point.global_position
	
	# 7. Avanza al siguiente enemigo en la lista para la próxima vez
	enemy_spawn_index += 1
	
	# --- INTEGRACIÓN MULTIJUGADOR ---
	# Si es una partida multijugador, notifica a los demás sobre el nuevo enemigo.
	if GameManager.is_multiplayer:
		var enemy_data = {
			"type": "spawn_enemy",
			"enemy_id": enemy_id,
			"tank_type_path": enemy.tank_type.resource_path,
			"position": {"x": enemy.global_position.x, "y": enemy.global_position.y}
		}
		NetworkManager.send_data(enemy_data)
