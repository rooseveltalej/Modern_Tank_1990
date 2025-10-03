extends Resource

class_name TankType

@export_enum("Basic", "Fast", "Power", "Armor") var tank_name: String = "Basic"
@export var speed:float = 100.0
@export var health: int = 1
@export var min_shoot_interval: float = 4.0
@export var max_shoot_interval: float = 8.0
@export var bullet_speed: float = 200.0
@export var points: int = 100
