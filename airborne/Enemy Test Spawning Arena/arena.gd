extends Node3D

@onready var spawner = $SpawnManager
@onready var spawn_queue = $SpawnQueue

func _ready():
	spawner.set_spawn_center(Vector3.ZERO)
	var points = []
	for child in $SpawnPoints.get_children():
		points.append(child)
	spawner.set_spawn_points(points)
	spawn_queue.set_spawner(spawner)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Connect trigger
	spawner.player_entered_range.connect(_on_player_entered)
	spawner.trigger_active = true  # activate the trigger

func _on_player_entered():
	print("Player entered arena — spawning!")
	spawn_queue.add_preset("full_squad")
	spawn_queue.start_queue()
