# spawn_queue.gd
extends Node

signal queue_started
signal group_spawned(group_index, types)
signal wave_completed(wave_index)
signal queue_finished

@export var delay_between_groups = 2.0
@export var wave_enemy_ttl = 5.0
@export var randomize_waves = false
@export var randomize_groups = false

var spawner: Node = null
var queue: Array = []
var is_running = false
var current_index = 0
var current_wave = 0
var wave_active = false
var wave_enemies: Array = []
var waves: Array = []

const PRESET_GROUPS = {
	"solo_melee": ["melee"],
	"solo_ranged": ["ranged"],
	"solo_flying": ["flying"],
	"basic_duo": ["melee", "ranged"],
	"air_support": ["flying", "melee"],
	"full_squad": ["melee", "ranged", "flying"],
}

func _ready():
	waves = [
		# Wave 1: 5 ranged, 9 melee
		[
			_repeat("ranged", 3),
			_repeat("ranged", 2),
			_repeat("melee", 3),
			_repeat("melee", 3),
			_repeat("melee", 3),
		],
		# Wave 2: 10 flying
		[
			_repeat("flying", 5),
			_repeat("flying", 5),
		],
		# Wave 3: 10 ranged, 10 melee, 5 flying
		[
			_repeat("ranged", 5),
			_repeat("ranged", 5),
			_repeat("melee", 5),
			_repeat("melee", 5),
			_repeat("flying", 5),
		],
	]

func _repeat(type: String, count: int) -> Array:
	var arr = []
	for i in count:
		arr.append(type)
	return arr

func set_spawner(s: Node):
	spawner = s
	spawner.enemy_spawned.connect(_on_wave_enemy_spawned)
	spawner.enemy_died.connect(_on_wave_enemy_died)

# --- Queue System ---

func add_group(types: Array):
	queue.append(types)

func add_preset(preset_name: String):
	if PRESET_GROUPS.has(preset_name):
		queue.append(PRESET_GROUPS[preset_name].duplicate())
	else:
		push_warning("SpawnQueue: unknown preset: " + preset_name)

func clear_queue():
	queue.clear()
	is_running = false
	current_index = 0

func start_queue(use_fixed_points: bool = false, randomize_order: bool = false):
	if queue.is_empty():
		push_warning("SpawnQueue: queue is empty!")
		return
	if randomize_order:
		queue.shuffle()
	is_running = true
	current_index = 0
	emit_signal("queue_started")
	_process_next(use_fixed_points, randomize_order)

func _process_next(use_fixed_points: bool = false, randomize_order: bool = false):
	if current_index >= queue.size():
		is_running = false
		emit_signal("queue_finished")
		return
	var group = queue[current_index]
	spawner.spawn_group(group, use_fixed_points, randomize_order)
	emit_signal("group_spawned", current_index, group)
	current_index += 1
	if current_index < queue.size():
		await get_tree().create_timer(delay_between_groups).timeout
		_process_next(use_fixed_points, randomize_order)
	else:
		is_running = false
		emit_signal("queue_finished")

func get_preset_names() -> Array:
	return PRESET_GROUPS.keys()

# --- Wave System ---

func start_waves(use_fixed_points: bool = false):
	current_wave = 0
	spawner.clear_all_enemies()
	var wave_order = waves.duplicate(true)
	if randomize_waves:
		wave_order.shuffle()
	print("Starting wave system — ", wave_order.size(), " waves total")
	_run_wave(wave_order, use_fixed_points)

func _run_wave(wave_order: Array, use_fixed_points: bool):
	if current_wave >= wave_order.size():
		print("All waves complete!")
		emit_signal("queue_finished")
		return

	wave_active = true
	wave_enemies.clear()

	print("=== WAVE ", current_wave + 1, " of ", wave_order.size(), " ===")

	var groups = wave_order[current_wave].duplicate(true)
	if randomize_groups:
		groups.shuffle()

	# Spawn each group with a delay between them
	for group in groups:
		if randomize_groups:
			group.shuffle()
		spawner.spawn_group(group, use_fixed_points, false)
		await get_tree().create_timer(delay_between_groups).timeout

	print("Wave ", current_wave + 1, " fully spawned — waiting for enemies to die or TTL...")

	# Poll for all enemies dead OR wait for TTL
	var elapsed = 0.0
	while elapsed < wave_enemy_ttl:
		await get_tree().create_timer(0.5).timeout
		elapsed += 0.5
		if spawner.get_enemy_count() == 0:
			print("All enemies cleared early!")
			break

	# Kill any remaining enemies
	if spawner.get_enemy_count() > 0:
		print("TTL expired — clearing remaining enemies")
		spawner.clear_all_enemies()

	emit_signal("wave_completed", current_wave)
	print("Wave ", current_wave + 1, " complete!")
	current_wave += 1

	if current_wave < wave_order.size():
		print("Next wave in 3 seconds...")
		await get_tree().create_timer(3.0).timeout
		_run_wave(wave_order, use_fixed_points)
	else:
		print("All waves complete!")
		emit_signal("queue_finished")

func _on_wave_enemy_spawned(enemy):
	if wave_active:
		wave_enemies.append(enemy)

func _on_wave_enemy_died(enemy):
	if wave_enemies.has(enemy):
		wave_enemies.erase(enemy)
