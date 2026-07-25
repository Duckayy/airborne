# arena_debug_menu.gd
extends CanvasLayer

var spawner: Node = null
var spawn_queue: Node = null
var menu_visible = true
var randomize_spawns = false

func _ready():
	await get_tree().process_frame
	spawner = get_tree().current_scene.get_node_or_null("SpawnManager")
	spawn_queue = get_tree().current_scene.get_node_or_null("SpawnQueue")
	_build_ui()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			menu_visible = !menu_visible
			$MenuRoot.visible = menu_visible
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_visible else Input.MOUSE_MODE_CAPTURED

func _build_ui():
	var root = Control.new()
	root.name = "MenuRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.08, 0.05, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20
	scroll.offset_top = 20
	scroll.offset_right = -20
	scroll.offset_bottom = -20
	root.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 500
	scroll.add_child(vbox)

	_add_label(vbox, "ARENA SPAWN MENU", 28)
	_add_label(vbox, "Press F1 to toggle | ESC = player menu", 14)
	_add_separator(vbox)

	# Randomize toggle
	_add_label(vbox, "OPTIONS", 18)
	var rand_btn = _add_button(vbox, "Randomize Order: OFF", Color(0.3, 0.3, 0.1))
	rand_btn.name = "RandBtn"
	rand_btn.pressed.connect(func():
		randomize_spawns = !randomize_spawns
		rand_btn.text = "Randomize Order: " + ("ON" if randomize_spawns else "OFF")
	)

	_add_separator(vbox)
	_add_label(vbox, "SPAWN SINGLE ENEMY", 18)

	# FIX: capture type variable explicitly to avoid closure bug
	for type in ["melee", "ranged", "flying"]:
		var captured_type = type  # capture explicitly
		var btn = _add_button(vbox, "Spawn " + type.capitalize())
		btn.pressed.connect(func(): spawner.spawn_enemy_random(captured_type))

	_add_separator(vbox)
	_add_label(vbox, "SPAWN PRESET GROUP (instant)", 18)

	# FIX: capture preset name explicitly
	if spawn_queue:
		for preset in spawn_queue.get_preset_names():
			var captured_preset = preset  # capture explicitly
			var btn = _add_button(vbox, "Spawn Group: " + preset, Color(0.1, 0.35, 0.5))
			btn.pressed.connect(func():
				var group = spawn_queue.PRESET_GROUPS[captured_preset].duplicate()
				if randomize_spawns:
					group.shuffle()
				spawner.spawn_group(group, false, randomize_spawns)
			)

	_add_separator(vbox)
	_add_label(vbox, "QUEUE GROUPS (delayed)", 18)

	if spawn_queue:
		for preset in spawn_queue.get_preset_names():
			var captured_preset = preset  # capture explicitly
			var btn = _add_button(vbox, "Queue: " + preset, Color(0.15, 0.25, 0.5))
			btn.pressed.connect(func():
				spawn_queue.add_preset(captured_preset)
			)

	var start_queue_btn = _add_button(vbox, "▶ Start Queue", Color(0.1, 0.5, 0.2))
	start_queue_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.start_queue(false, randomize_spawns)
	)

	var start_queue_fixed_btn = _add_button(vbox, "▶ Start Queue (Fixed Points)", Color(0.1, 0.4, 0.2))
	start_queue_fixed_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.start_queue(true, randomize_spawns)
	)

	var clear_queue_btn = _add_button(vbox, "Clear Queue", Color(0.4, 0.2, 0.1))
	clear_queue_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.clear_queue()
	)

	_add_separator(vbox)
	_add_label(vbox, "WAVE SYSTEM", 18)

	var wave_btn = _add_button(vbox, "▶ Start Waves (Random Points)", Color(0.5, 0.1, 0.5))
	wave_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.start_waves(false)
	)

	var wave_fixed_btn = _add_button(vbox, "▶ Start Waves (Fixed Points)", Color(0.4, 0.1, 0.4))
	wave_fixed_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.start_waves(true)
	)

	_add_separator(vbox)
	_add_label(vbox, "ARENA CONTROLS", 18)

	var clear_btn = _add_button(vbox, "🗑 Clear All Enemies", Color(0.8, 0.1, 0.1))
	clear_btn.pressed.connect(func(): spawner.clear_all_enemies())

	var quit_btn = _add_button(vbox, "Quit", Color(0.5, 0.05, 0.05))
	quit_btn.pressed.connect(get_tree().quit)

func _add_label(parent, text: String, size: int = 16) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(lbl)
	return lbl

func _add_button(parent, text: String, color: Color = Color(0.1, 0.4, 0.2)) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 42)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.9, 0.5, 0.4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(btn)
	return btn

func _add_separator(parent):
	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 8
	parent.add_child(sep)
