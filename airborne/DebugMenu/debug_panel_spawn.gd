# debug_panel_spawn.gd
# Only active when SpawnManager exists in the scene
extends Node

var spawner: Node = null
var spawn_queue: Node = null
var debug_menu: Node = null
var randomize_spawns = false

func _ready():
	await get_tree().process_frame
	spawner = get_tree().current_scene.get_node_or_null("SpawnManager")
	spawn_queue = get_tree().current_scene.get_node_or_null("SpawnQueue")
	debug_menu = get_parent()

	# Only register if spawner exists in this scene
	if spawner == null:
		return

	if debug_menu and debug_menu.has_method("register_panel"):
		debug_menu.register_panel("SPAWN", _build)

func _build(content: Control):
	# Randomize toggle
	var rand_btn = DebugMenu.make_button(content, "Randomize Order: OFF", Color(0.3, 0.3, 0.1))
	rand_btn.pressed.connect(func():
		randomize_spawns = !randomize_spawns
		rand_btn.text = "Randomize Order: " + ("ON" if randomize_spawns else "OFF")
	)

	DebugMenu.make_label(content, "Single Enemy", 15)

	for type in ["melee", "ranged", "flying"]:
		var captured = type
		var btn = DebugMenu.make_button(content, "Spawn " + type.capitalize())
		btn.pressed.connect(func(): spawner.spawn_enemy_random(captured))

	DebugMenu.make_label(content, "Spawn Group (instant)", 15)

	if spawn_queue:
		for preset in spawn_queue.get_preset_names():
			var captured = preset
			var btn = DebugMenu.make_button(content, "Group: " + preset, Color(0.1, 0.3, 0.5))
			btn.pressed.connect(func():
				var group = spawn_queue.PRESET_GROUPS[captured].duplicate()
				if randomize_spawns:
					group.shuffle()
				spawner.spawn_group(group, false, randomize_spawns)
			)

	DebugMenu.make_label(content, "Queue", 15)

	if spawn_queue:
		for preset in spawn_queue.get_preset_names():
			var captured = preset
			var btn = DebugMenu.make_button(content, "Queue: " + preset, Color(0.1, 0.2, 0.45))
			btn.pressed.connect(func(): spawn_queue.add_preset(captured))

	var start_btn = DebugMenu.make_button(content, "▶ Start Queue", Color(0.1, 0.5, 0.2))
	start_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.start_queue(false, randomize_spawns)
	)

	var clear_queue_btn = DebugMenu.make_button(content, "Clear Queue", Color(0.4, 0.2, 0.1))
	clear_queue_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.clear_queue()
	)

	DebugMenu.make_label(content, "Waves", 15)

	var wave_btn = DebugMenu.make_button(content, "▶ Start Waves", Color(0.5, 0.1, 0.5))
	wave_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.start_waves(false)
	)

	DebugMenu.make_label(content, "Arena Controls", 15)

	var clear_btn = DebugMenu.make_button(content, "🗑 Clear All Enemies", Color(0.8, 0.1, 0.1))
	clear_btn.pressed.connect(func(): spawner.clear_all_enemies())

	var quit_btn = DebugMenu.make_button(content, "Quit", Color(0.5, 0.05, 0.05))
	quit_btn.pressed.connect(get_tree().quit)
