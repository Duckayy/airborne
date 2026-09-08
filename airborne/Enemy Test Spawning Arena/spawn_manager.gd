# spawner.gd
extends Node

signal enemy_spawned(enemy)
signal enemy_died(enemy)
signal all_enemies_cleared
signal player_entered_range

@export var spawn_radius = 10.0
@export var spawn_height = 0.5
@export var player_trigger_range = 15.0

const ENEMY_SCENES = {
	"melee": "res://Enemies V3 (Inheretence)/CloseRangeEnemiesV3/EnemiesV3.tscn",
	"ranged": "res://Enemies V3 (Inheretence)/RangedEnemiesV3/RangedEnemiesV3.tscn",
	"flying": "res://Enemies V3 (Inheretence)/FlyingEnemiesV3/FlyingEnemyV3.tscn",
}

var active_enemies: Array = []
var spawn_points: Array = []
var spawn_center: Vector3 = Vector3.ZERO
var player: Node3D = null
var trigger_active = false

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if not trigger_active or player == null:
		return
	var dist = spawn_center.distance_to(player.global_position)
	if dist <= player_trigger_range:
		trigger_active = false
		emit_signal("player_entered_range")

func set_spawn_center(pos: Vector3):
	spawn_center = pos

func set_spawn_points(points: Array):
	spawn_points = points

func spawn_enemy(type: String, position: Vector3 = Vector3.ZERO) -> Node:
	if not ENEMY_SCENES.has(type):
		push_error("Spawner: unknown enemy type: " + type)
		return null
	var scene = load(ENEMY_SCENES[type])
	if scene == null:
		push_error("Spawner: could not load scene for: " + type)
		return null
	var enemy = scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	
	# Wait one physics frame before setting position
	# so the enemy's collision is registered before it moves
	await get_tree().physics_frame
	enemy.global_position = position + Vector3(0, 1.5, 0)  # spawn above ground
	
	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))
	emit_signal("enemy_spawned", enemy)
	return enemy

func spawn_enemy_random(type: String) -> Node:
	var angle = randf_range(0, TAU)
	var radius = randf_range(spawn_radius * 0.5, spawn_radius)
	var pos = spawn_center + Vector3(cos(angle) * radius, spawn_height, sin(angle) * radius)
	return await spawn_enemy(type, pos)

func spawn_enemy_at_point(type: String, point_index: int) -> Node:
	if spawn_points.is_empty():
		push_warning("Spawner: no spawn points set, falling back to random")
		return await spawn_enemy_random(type)
	var idx = clamp(point_index, 0, spawn_points.size() - 1)
	return await spawn_enemy(type, spawn_points[idx].global_position)

func spawn_group(types: Array, use_fixed_points: bool = false, randomize_order: bool = false):
	var order = types.duplicate()
	if randomize_order:
		order.shuffle()
	for i in order.size():
		if use_fixed_points and not spawn_points.is_empty():
			# Randomize which spawn point is used
			var point_idx = randi() % spawn_points.size()
			spawn_enemy_at_point(order[i], point_idx)
		else:
			spawn_enemy_random(order[i])

func clear_all_enemies():
	for enemy in active_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	emit_signal("all_enemies_cleared")

func get_enemy_count() -> int:
	return active_enemies.size()

func _on_enemy_removed(enemy):
	if active_enemies.has(enemy):
		active_enemies.erase(enemy)
	emit_signal("enemy_died", enemy)
