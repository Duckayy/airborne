extends BaseEnemy

@export var hover_height = 5.0
@export var bob_amplitude = 0.3
@export var bob_speed = 2.0
@export var chase_speed = 8.0
@export var hover_distance = 8.0
@export var dive_speed = 18.0
@export var dive_range = 12.0
@export var dive_cooldown = 4.0
@export var dive_overshoot = 6.0
@export var shots_before_dive = 3
@export var shoot_range = 14.0
@export var shoot_cooldown = 1.2

var can_dive = true
var can_shoot = true
var has_line_of_sight = false
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

enum State { IDLE_HOVER, CHASE_HOVER, DIVE, RECOVER }
var state = State.IDLE_HOVER

func _enemy_ready():
	home_position = global_position
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func(): can_attack = true)
	dive_cooldown_timer.wait_time = dive_cooldown
	dive_cooldown_timer.one_shot = true
	dive_cooldown_timer.timeout.connect(func(): can_dive = true)
	shoot_cooldown_timer.wait_time = shoot_cooldown
	shoot_cooldown_timer.one_shot = true
	shoot_cooldown_timer.timeout.connect(func(): can_shoot = true)

func _physics_process(delta):
	if is_dead:
		return
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
	if can_shoot and has_line_of_sight and dist <= shoot_range:
		_shoot()
	if shots_fired >= shots_before_dive and can_dive and has_line_of_sight and dist <= dive_range:
		_start_dive()

func _do_idle_hover(delta):
	var bob_offset = sin(bob_timer * bob_speed) * bob_amplitude
	var target_y = home_position.y + bob_offset
	velocity.x = move_toward(velocity.x, 0, 10 * delta)
	velocity.z = move_toward(velocity.z, 0, 10 * delta)
	velocity.y = (target_y - global_position.y) * 5.0

func _do_chase_hover(_delta):
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
	dive_end_pos.y = dive_start_pos.y
	state = State.DIVE

func _do_dive(delta):
	var total_dist = dive_start_pos.distance_to(dive_end_pos)
	var progress_speed = dive_speed / max(total_dist, 1.0)
	dive_progress = min(dive_progress + progress_speed * delta, 1.0)
	var horizontal_pos = dive_start_pos.lerp(dive_end_pos, dive_progress)
	var player_y = player.global_position.y if player else dive_start_pos.y
	var dip_curve = sin(dive_progress * PI)
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
			_do_attack()
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

func _on_death():
	state = State.IDLE_HOVER
	await get_tree().create_timer(0.5).timeout
	queue_free()
