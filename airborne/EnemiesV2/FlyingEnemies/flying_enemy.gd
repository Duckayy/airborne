extends CharacterBody3D

@export var max_health = 60.0
@export var hover_height = 5.0
@export var bob_amplitude = 0.3
@export var bob_speed = 2.0
@export var detection_range = 20.0
@export var chase_speed = 8.0
@export var hover_distance = 8.0
@export var dive_speed = 18.0
@export var dive_range = 12.0
@export var dive_cooldown = 4.0
@export var dive_overshoot = 6.0
@export var dive_dip_depth = 3        # how low it dips at the peak of the swoop
@export var shots_before_dive = 3
@export var attack_damage = 15.0
@export var attack_cooldown = 1.0
@export var shoot_range = 14.0
@export var shoot_cooldown = 1.2
@export var health_bar_visible_range = 10.0

var health = max_health
var player: Node3D = null
var can_attack = true
var can_dive = true
var can_shoot = true
var has_line_of_sight = false
var has_taken_damage = false
var bob_timer = 0.0
var home_position: Vector3
var dive_start_pos: Vector3
var dive_end_pos: Vector3
var dive_progress = 0.0
var has_hit_player_this_dive = false
var shots_fired = 0

@onready var attack_timer = $AttackTimer
@onready var dive_cooldown_timer = $DiveCooldownTimer
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var los_ray = $LineOfSightRay
@onready var health_bar_anchor = $HealthBarAnchor
@onready var health_bar_sprite = $HealthBarAnchor/HealthBarSprite
@onready var health_viewport = $HealthBarAnchor/HealthBarViewport
@onready var progress_bar = $HealthBarAnchor/HealthBarViewport/HealthProgressBar

enum State { IDLE_HOVER, CHASE_HOVER, DIVE, RECOVER }
var state = State.IDLE_HOVER

func _ready():
	player = get_tree().get_first_node_in_group("player")
	home_position = global_position

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_done)

	dive_cooldown_timer.wait_time = dive_cooldown
	dive_cooldown_timer.one_shot = true
	dive_cooldown_timer.timeout.connect(_on_dive_cooldown_done)

	shoot_cooldown_timer.wait_time = shoot_cooldown
	shoot_cooldown_timer.one_shot = true
	shoot_cooldown_timer.timeout.connect(_on_shoot_cooldown_done)

	progress_bar.max_value = max_health
	progress_bar.value = health

	await get_tree().process_frame
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

func _physics_process(delta):
	bob_timer += delta
	_check_line_of_sight()
	_update_state()
	_update_health_bar_visibility()

	match state:
		State.IDLE_HOVER:
			_do_idle_hover(delta)
		State.CHASE_HOVER:
			_do_chase_hover(delta)
		State.DIVE:
			_do_dive(delta)
		State.RECOVER:
			_do_recover(delta)

	move_and_slide()

func _check_line_of_sight():
	if player == null:
		has_line_of_sight = false
		return
	los_ray.target_position = los_ray.to_local(player.global_position)
	los_ray.force_raycast_update()
	if los_ray.is_colliding():
		has_line_of_sight = los_ray.get_collider() == player
	else:
		has_line_of_sight = false

func _update_state():
	if player == null:
		state = State.IDLE_HOVER
		return

	if state == State.DIVE or state == State.RECOVER:
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		state = State.IDLE_HOVER
		shots_fired = 0
		return

	state = State.CHASE_HOVER

	# Shoot from range, building toward a dive
	if can_shoot and has_line_of_sight and dist <= shoot_range:
		_shoot()

	# After enough shots, commit to a dive once close enough
	if shots_fired >= shots_before_dive and can_dive and has_line_of_sight and dist <= dive_range:
		_start_dive()

func _do_idle_hover(delta):
	var bob_offset = sin(bob_timer * bob_speed) * bob_amplitude
	var target_y = home_position.y + bob_offset

	velocity.x = move_toward(velocity.x, 0, 10 * delta)
	velocity.z = move_toward(velocity.z, 0, 10 * delta)
	velocity.y = (target_y - global_position.y) * 5.0

func _do_chase_hover(delta):
	var to_player = player.global_position - global_position
	to_player.y = 0
	var horizontal_dist = to_player.length()

	var move_dir = Vector3.ZERO
	if horizontal_dist > hover_distance:
		move_dir = to_player.normalized()
	elif horizontal_dist < hover_distance * 0.7:
		move_dir = -to_player.normalized()

	velocity.x = move_dir.x * chase_speed
	velocity.z = move_dir.z * chase_speed

	var target_y = player.global_position.y + hover_height + sin(bob_timer * bob_speed) * bob_amplitude
	velocity.y = (target_y - global_position.y) * 5.0

	var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	if look_target != global_position:
		look_at(look_target, Vector3.UP)

func _shoot():
	can_shoot = false
	shoot_cooldown_timer.start()
	shots_fired += 1
	# PROJECTILE LOGIC - TO BE ADDED LATER
	# var projectile = preload("res://Projectiles/Projectile.tscn").instantiate()
	# get_tree().current_scene.add_child(projectile)
	# projectile.global_position = global_position
	# projectile.direction = (player.global_position - global_position).normalized()
	print("*** Flying enemy shoots! (", shots_fired, "/", shots_before_dive, ") ***")

func _on_shoot_cooldown_done():
	can_shoot = true

func _start_dive():
	can_dive = false
	can_shoot = false
	has_hit_player_this_dive = false
	shots_fired = 0
	dive_cooldown_timer.start()
	dive_progress = 0.0

	dive_start_pos = global_position

	var direction_to_player = (player.global_position - global_position).normalized()
	dive_end_pos = player.global_position + direction_to_player * dive_overshoot
	dive_end_pos.y = dive_start_pos.y  # end at same height as start

	state = State.DIVE
	print("*** Flying enemy DIVES through player! ***")

func _do_dive(delta):
	var total_dist = dive_start_pos.distance_to(dive_end_pos)
	var progress_speed = dive_speed / max(total_dist, 1.0)
	dive_progress = min(dive_progress + progress_speed * delta, 1.0)

	var horizontal_pos = dive_start_pos.lerp(dive_end_pos, dive_progress)

	# Dip down toward the PLAYER's height at the midpoint, not an arbitrary depth
	var player_y = player.global_position.y if player else dive_start_pos.y
	var dip_curve = sin(dive_progress * PI)  # 0 at start/end, 1 at midpoint
	horizontal_pos.y = lerp(dive_start_pos.y, player_y, dip_curve)

	var move_dir = (horizontal_pos - global_position)
	if move_dir.length() > 0.01:
		velocity = move_dir / delta
		var look_target = global_position + move_dir.normalized()
		look_at(look_target, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	if player and not has_hit_player_this_dive:
		var player_dist = global_position.distance_to(player.global_position)
		if player_dist < 2.5:
			_attack()
			has_hit_player_this_dive = true

	if dive_progress >= 1.0:
		state = State.RECOVER

func _do_recover(delta):
	velocity.x = move_toward(velocity.x, 0, 15 * delta)
	velocity.z = move_toward(velocity.z, 0, 15 * delta)

	var target_y = player.global_position.y + hover_height if player else home_position.y
	velocity.y = (target_y - global_position.y) * 3.0

	if abs(global_position.y - target_y) < 0.5:
		state = State.CHASE_HOVER

func _attack():
	if not can_attack:
		return
	can_attack = false
	attack_timer.start()
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)
	print("*** Flying enemy hits player on dive! ***")

func _on_attack_cooldown_done():
	can_attack = true

func _on_dive_cooldown_done():
	can_dive = true

func _update_health_bar_visibility():
	if player == null or not has_taken_damage:
		health_bar_anchor.visible = false
		return
	var dist = global_position.distance_to(player.global_position)
	health_bar_anchor.visible = dist <= health_bar_visible_range

func take_damage(amount: float):
	has_taken_damage = true
	health -= amount
	health = clamp(health, 0, max_health)
	progress_bar.value = health
	health_viewport.get_node("HPLabel").text = str(int(health)) + " / " + str(int(max_health))
	if health <= 0:
		_die()

func _die():
	health_bar_anchor.visible = false
	queue_free()
