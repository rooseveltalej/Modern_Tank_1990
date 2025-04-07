extends Node2D

const TOTAL_ENEMIES_PER_LEVEL = 20
const MAX_ENEMIES_ON_SCREEN = 4
const SPAWN_DELAY = 2.0

const ENEMY_SCENE = preload("res://Scenes/enemy.tscn")

var enemies_remaining = TOTAL_ENEMIES_PER_LEVEL
var current_enemies = 0
var enemy_spawn_index = 0

@onready var spawn_points: Array[Marker2D] = [
	$SpawnPoints/SpawnLeft,
	$SpawnPoints/SpawnCenter,
	$SpawnPoints/SpawnRight
]

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.wait_time = SPAWN_DELAY
	spawn_timer.timeout.connect(spawn_enemy)

func spawn_enemy():
	if enemies_remaining <= 0:
		if current_enemies == 0:
			print("Level complete")
		return
	
	if current_enemies >= MAX_ENEMIES_ON_SCREEN:
		return
	
	var random_spawn_point = spawn_points.pick_random()
	
	var enemy = ENEMY_SCENE.instantiate()
	enemy.position = random_spawn_point.position
	
	if not is_inside_tree():
		return
	
	get_tree().root.add_child.call_deferred(enemy)
	
	enemy.connect('tree_exited', on_enemy_destroyed)
	
	current_enemies += 1
	enemies_remaining -= 1
	enemy_spawn_index += 1
	spawn_timer.start()
	
	print_debug("Spawned enemy. On screen: ", current_enemies, " Remainig: ", enemies_remaining)
	
func on_enemy_destroyed():
	current_enemies -= 1
	if enemies_remaining > 0 and current_enemies < MAX_ENEMIES_ON_SCREEN:
		spawn_enemy()
	elif enemies_remaining > 0:
		spawn_timer.start()
			
