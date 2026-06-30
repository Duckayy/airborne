# arena_debug_menu.gd
# Attach to a CanvasLayer node in the arena scene.

extends CanvasLayer

var spawner: Node = null
var spawn_queue: Node = null
var menu_visible = true

func _ready():
	# Wait one frame so spawner/queue are ready
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

	# Dark background panel
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	# Scroll container
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

	_add_label(vbox, "ARENA DEBUG MENU", 28)
	_add_label(vbox, "Press ESC to toggle", 14)
	_add_separator(vbox)

	# Enemy count display
	_add_label(vbox, "SPAWN SINGLE ENEMY", 18)
	for type in ["melee", "ranged", "flying"]:
		var btn = _add_button(vbox, "Spawn " + type.capitalize())
		btn.pressed.connect(func(): spawner.spawn_enemy_random(type))

	_add_separator(vbox)
	_add_label(vbox, "SPAWN PRESET GROUP", 18)

	if spawn_queue:
		for preset in spawn_queue.get_preset_names():
			var btn = _add_button(vbox, "Queue: " + preset)
			btn.pressed.connect(func():
				spawn_queue.add_preset(preset)
				spawn_queue.start_queue()
			)

	_add_separator(vbox)
	_add_label(vbox, "QUEUE ACTIONS", 18)

	var start_btn = _add_button(vbox, "Start Queue (Fixed Points)")
	start_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.start_queue(true)
	)

	var clear_queue_btn = _add_button(vbox, "Clear Queue")
	clear_queue_btn.pressed.connect(func():
		if spawn_queue:
			spawn_queue.clear_queue()
	)

	_add_separator(vbox)
	_add_label(vbox, "ARENA CONTROLS", 18)

	var clear_btn = _add_button(vbox, "Clear All Enemies", Color(0.8, 0.1, 0.1))
	clear_btn.pressed.connect(func(): spawner.clear_all_enemies())

	var quit_btn = _add_button(vbox, "Quit", Color(0.5, 0.1, 0.1))
	quit_btn.pressed.connect(get_tree().quit)

# --- UI Helpers ---

func _add_label(parent, text: String, size: int = 16) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(lbl)
	return lbl

func _add_button(parent, text: String, color: Color = Color(0.2, 0.2, 0.8)) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 40)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	parent.add_child(btn)
	return btn

func _add_separator(parent):
	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 10
	parent.add_child(sep)
