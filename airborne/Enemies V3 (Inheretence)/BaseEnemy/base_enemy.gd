extends CharacterBody3D
class_name BaseEnemy

signal died

@export var max_health = 100.0
@export var attack_damage = 10.0
@export var attack_cooldown = 1.5
@export var detection_range = 20.0
@export var fall_acceleration = 60.0
@export var health_bar_visible_range = 10.0

var health = max_health
var player: Node3D = null
var can_attack = true
var has_taken_damage = false
var is_dead = false

var health_bar_anchor: Node3D = null
var health_bar_sprite: Sprite3D = null
var health_viewport: SubViewport = null
var progress_bar: ProgressBar = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	_setup_health_bar()
	_enemy_ready()

func _enemy_ready():
	pass

func _setup_health_bar():
	# HealthBarAnchor is a child of CharacterBody3D which is us
	health_bar_anchor = get_node_or_null("HealthBarAnchor")
	if health_bar_anchor == null:
		push_warning("BaseEnemy: HealthBarAnchor not found on " + name)
		return
	health_bar_sprite = health_bar_anchor.get_node_or_null("HealthBarSprite")
	health_viewport = health_bar_anchor.get_node_or_null("HealthBarViewport")
	if health_viewport == null:
		push_warning("BaseEnemy: HealthBarViewport not found")
		return
	progress_bar = health_viewport.get_node_or_null("HealthProgressBar")
	if progress_bar == null:
		push_warning("BaseEnemy: HealthProgressBar not found")
		return
	progress_bar.max_value = max_health
	progress_bar.value = health
	await get_tree().process_frame
	if health_bar_sprite and health_viewport:
		health_bar_sprite.texture = health_viewport.get_texture()
		health_bar_sprite.pixel_size = 0.005
	health_bar_anchor.visible = false
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.0, 0.0, 1.0)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.show_percentage = false
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.add_theme_font_size_override("font_size", 20)
	hp_label.add_theme_color_override("font_color", Color.BLACK)
	hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_viewport.add_child(hp_label)
	hp_label.text = str(int(health)) + " / " + str(int(max_health))

func _update_health_bar():
	if progress_bar == null:
		return
	progress_bar.value = health
	var label = health_viewport.get_node_or_null("HPLabel")
	if label:
		label.text = str(int(health)) + " / " + str(int(max_health))

func _update_health_bar_visibility():
	if health_bar_anchor == null:
		return
	if player == null or not has_taken_damage:
		health_bar_anchor.visible = false
		return
	var dist = global_position.distance_to(player.global_position)
	health_bar_anchor.visible = dist <= health_bar_visible_range

func take_damage(amount: float):
	if is_dead:
		return
	has_taken_damage = true
	health -= amount
	health = clamp(health, 0, max_health)
	_update_health_bar()
	if health <= 0:
		_die()

func _do_attack():
	if not can_attack or player == null or is_dead:
		return
	can_attack = false
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

func _die():
	if is_dead:
		return
	is_dead = true
	if health_bar_anchor:
		health_bar_anchor.visible = false
	emit_signal("died")
	_on_death()

func _on_death():
	await get_tree().create_timer(0.5).timeout
	queue_free()
