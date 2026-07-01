# spawn_queue.gd
# Attach to any Node alongside spawner.gd
# Manages a queue of spawn groups, processes them with a delay between each.

extends Node

signal queue_started
signal group_spawned(group_index, types)
signal queue_finished

@export var delay_between_groups = 1.5  # seconds between each group spawning

var spawner: Node = null   # set this from the arena after _ready
var queue: Array = []      # array of arrays: [["melee","ranged"], ["flying","melee"]]
var is_running = false
var current_index = 0

# Preset groups - add your own combos here
const PRESET_GROUPS = {
	"solo_melee": ["melee"],
	"solo_ranged": ["ranged"],
	"solo_flying": ["flying"],
	"basic_duo": ["melee", "ranged"],
	"air_support": ["flying", "melee"],
	"full_squad": ["melee", "melee", "ranged"],
	"chaos": ["flying", "melee", "ranged"],
}

func set_spawner(s: Node):
	spawner = s

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

func start_queue(use_fixed_points: bool = false):
	if queue.is_empty():
		push_warning("SpawnQueue: queue is empty!")
		return
	is_running = true
	current_index = 0
	emit_signal("queue_started")
	_process_next(use_fixed_points)

func _process_next(use_fixed_points: bool = false):
	if current_index >= queue.size():
		is_running = false
		emit_signal("queue_finished")
		return

	var group = queue[current_index]
	spawner.spawn_group(group, use_fixed_points)
	emit_signal("group_spawned", current_index, group)
	current_index += 1

	if current_index < queue.size():
		await get_tree().create_timer(delay_between_groups).timeout
		_process_next(use_fixed_points)
	else:
		is_running = false
		emit_signal("queue_finished")

func get_preset_names() -> Array:
	return PRESET_GROUPS.keys()
