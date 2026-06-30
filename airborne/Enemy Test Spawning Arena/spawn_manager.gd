# spawner.gd
# Attach to any Node. Handles all enemy spawning logic.
# To use in a new scene: instance this node, connect signals, call spawn methods.

extends Node

signal enemy_spawned(enemy)
signal enemy_died(enemy)
signal all_enemies_cleared

@export var spawn_radius = 10.0   # radius for random spawns
@export var spawn_height = 0.5    # Y offset above ground

# Paths to your enemy scenes - update these to match your project
const ENEMY_SCENES = {
	"melee": "res://EnemiesV2/CloseRangeEnemies/EnemiesV2.tscn",
	"ranged": "res://EnemiesV2/RangedEnemies/RangedEnemies.tscn",
	"flying": "res://EnemiesV2/FlyingEnemies/FlyingEnemy.tscn",
}

var active_enemies: Array = []
var spawn_points: Array = []   # Node3D positions set from outside
var spawn_center: Vector3 = Vector3.ZERO

func _ready():
	pass

# --- Public API ---

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
	enemy.global_position = position
	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))
	emit_signal("enemy_spawned", enemy)
	return enemy

func spawn_enemy_random(type: String) -> Node:
	var angle = randf_range(0, TAU)
	var radius = randf_range(spawn_radius * 0.5, spawn_radius)
	var pos = spawn_center + Vector3(cos(angle) * radius, spawn_height, sin(angle) * radius)
	return spawn_enemy(type, pos)

func spawn_enemy_at_point(type: String, point_index: int) -> Node:
	if spawn_points.is_empty():
		push_warning("Spawner: no spawn points set, falling back to random")
		return spawn_enemy_random(type)
	var idx = clamp(point_index, 0, spawn_points.size() - 1)
	return spawn_enemy(type, spawn_points[idx].global_position)

func spawn_group(types: Array, use_fixed_points: bool = false):
	for i in types.size():
		if use_fixed_points and not spawn_points.is_empty():
			spawn_enemy_at_point(types[i], i % spawn_points.size())
		else:
			spawn_enemy_random(types[i])

func clear_all_enemies():
	for enemy in active_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	emit_signal("all_enemies_cleared")

func get_enemy_count() -> int:
	return active_enemies.size()

# --- Internal ---

func _on_enemy_removed(enemy):
	if active_enemies.has(enemy):
		active_enemies.erase(enemy)
	emit_signal("enemy_died", enemy)
