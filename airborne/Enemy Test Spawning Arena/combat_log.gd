# combat_log.gd
# Attach to a CanvasLayer node in the arena scene
extends CanvasLayer

@export var max_entries = 12
@export var entry_lifetime = 4.0
@export var fade_time = 1.0

var entries: Array = []
var vbox: VBoxContainer = null
var wave_label: Label = null
var enemy_count_label: Label = null
var spawner: Node = null
var spawn_queue: Node = null


func _ready():
	await get_tree().process_frame
	spawner = get_tree().current_scene.get_node_or_null("SpawnManager")
	spawn_queue = get_tree().current_scene.get_node_or_null("SpawnQueue")
	_build_ui()
	_connect_signals()

func _build_ui():
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Top right panel
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.55)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(280, 0)
	panel.set_anchor(SIDE_RIGHT, 1.0)
	panel.set_anchor(SIDE_LEFT, 1.0)
	panel.offset_left = -300
	panel.offset_right = -10
	panel.offset_top = 10
	root.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(outer_vbox)

	# Wave and enemy count header
	var header_bg = ColorRect.new()
	header_bg.color = Color(0.1, 0.1, 0.1, 0.8)
	header_bg.custom_minimum_size.y = 2
	outer_vbox.add_child(header_bg)

	wave_label = Label.new()
	wave_label.text = "WAVE — / —"
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(wave_label)

	enemy_count_label = Label.new()
	enemy_count_label.text = "Enemies: 0"
	enemy_count_label.add_theme_font_size_override("font_size", 13)
	enemy_count_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	enemy_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(enemy_count_label)

	var sep = HSeparator.new()
	outer_vbox.add_child(sep)

	# Kill feed entries
	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	outer_vbox.add_child(vbox)

func _connect_signals():
	if spawner:
		spawner.enemy_spawned.connect(_on_enemy_spawned)
		spawner.enemy_died.connect(_on_enemy_died)
		spawner.all_enemies_cleared.connect(_on_all_cleared)

	if spawn_queue:
		spawn_queue.wave_completed.connect(_on_wave_completed)
		spawn_queue.queue_started.connect(func(): log_entry("Queue started", Color(0.5, 0.8, 1.0)))
		spawn_queue.queue_finished.connect(func(): log_entry("Queue finished", Color(0.5, 0.8, 1.0)))

	# Connect player death if player exists
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)

func _process(_delta):
	# Update enemy count every frame
	if spawner:
		enemy_count_label.text = "Enemies on field: " + str(spawner.get_enemy_count())

func _on_enemy_spawned(enemy):
	var type = _get_enemy_type(enemy)
	log_entry("↑ " + type + " spawned", _type_color(type))
	_update_wave_label()

func _on_enemy_died(enemy):
	var type = _get_enemy_type(enemy)
	log_entry("✕ " + type + " killed", Color(0.9, 0.3, 0.3))

func _on_all_cleared():
	log_entry("All enemies cleared", Color(1.0, 0.5, 0.0))

func _on_wave_completed(wave_index):
	log_entry("✓ Wave " + str(wave_index + 1) + " complete!", Color(0.3, 1.0, 0.4))
	_update_wave_label()

func _on_player_died():
	log_entry("✦ PLAYER DIED", Color(1.0, 0.1, 0.1))

func _update_wave_label():
	if spawn_queue:
		var current = spawn_queue.current_wave
		var total = spawn_queue.waves.size()
		if spawn_queue.wave_active or current > 0:
			wave_label.text = "WAVE " + str(min(current + 1, total)) + " / " + str(total)
		else:
			wave_label.text = "WAVE — / —"
	else:
		wave_label.text = "ARENA"

func _get_enemy_type(enemy) -> String:
	if not is_instance_valid(enemy):
		return "Unknown"
	var scene_path = enemy.scene_file_path
	if "Flying" in scene_path or "flying" in scene_path:
		return "Flying"
	elif "Ranged" in scene_path or "ranged" in scene_path:
		return "Ranged"
	elif "Melee" in scene_path or "melee" in scene_path or "Enemies" in scene_path:
		return "Melee"
	return enemy.name

func _type_color(type: String) -> Color:
	match type:
		"Flying": return Color(0.4, 0.8, 1.0)
		"Ranged": return Color(1.0, 0.7, 0.2)
		"Melee": return Color(0.9, 0.4, 0.4)
		_: return Color(0.8, 0.8, 0.8)

func log_entry(text: String, color: Color = Color.WHITE):
	# Remove oldest if over limit
	if entries.size() >= max_entries:
		var oldest = entries.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	lbl.modulate.a = 1.0
	vbox.add_child(lbl)
	entries.append(lbl)

	# Fade out after lifetime
	_fade_entry(lbl)

func _fade_entry(lbl: Label):
	if not is_instance_valid(lbl) or not is_inside_tree():
		return
	var timer = get_tree()
	if timer == null:
		return
	await get_tree().create_timer(entry_lifetime).timeout
	if not is_instance_valid(lbl) or not is_inside_tree():
		return
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, fade_time)
	await tween.finished
	if is_instance_valid(lbl):
		entries.erase(lbl)
		lbl.queue_free()
