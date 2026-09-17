extends BaseEnemy

@export var move_speed = 6.0
@export var dash_speed = 16.0
@export var ideal_range = 12.0
@export var danger_range = 7.0
@export var max_range = 18.0
@export var telegraph_time = 0.8
@export var dash_cooldown = 1.5
@export var dash_distance = 8.0

var can_dash = true
var has_line_of_sight = false
var dash_waypoints: Array = []
var dash_waypoint_index = 0
var dash_target_position: Vector3

@onready var attack_timer = $AttackTimer
@onready var dash_cooldown_timer = $DashCooldownTimer
@onready var los_ray = $LineOfSightRay

enum State { IDLE, DASH_AWAY, PLANT, TELEGRAPH, ATTACK, REPOSITION }
var state = State.IDLE

func _enemy_ready():
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_done)
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.timeout.connect(func(): can_dash = true)

func _physics_process(delta):
	if is_dead:
		return
	if state != State.DASH_AWAY:
		_check_line_of_sight()
		_update_state()
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	_update_health_bar_visibility()
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
		State.DASH_AWAY:
			_do_dash_away()
		State.REPOSITION:
			_move_to_ideal_range()
		State.PLANT, State.TELEGRAPH, State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, 20 * delta)
			velocity.z = move_toward(velocity.z, 0, 20 * delta)
			if state == State.PLANT and can_attack and has_line_of_sight:
				_start_telegraph()
	if player and state != State.DASH_AWAY:
		var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		if look_target != global_position:
			look_at(look_target, Vector3.UP)
	move_and_slide()

func _check_line_of_sight():
	if player == null:
		has_line_of_sight = false
		return
	los_ray.target_position = los_ray.to_local(player.global_position + Vector3.UP)
	los_ray.force_raycast_update()
	if los_ray.is_colliding():
		has_line_of_sight = los_ray.get_collider() == player
	else:
		has_line_of_sight = false

func _update_state():
	if player == null:
		state = State.IDLE
		return
	if state == State.TELEGRAPH or state == State.ATTACK:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range:
		state = State.IDLE
		return
	if dist < danger_range and can_dash:
		_start_dash_away()
		return
	if dist > max_range:
		state = State.REPOSITION
	elif dist < danger_range:
		state = State.REPOSITION
	else:
		state = State.PLANT

func _start_dash_away():
	if player == null:
		return
	var away_direction = (global_position - player.global_position).normalized()
	var perpendicular = away_direction.cross(Vector3.UP).normalized()
	var side = 1 if randf() > 0.5 else -1
	var this_dash_distance = randf_range(7.0, dash_distance)
	var juke_point = global_position + (perpendicular * side * this_dash_distance * 0.5) + (away_direction * this_dash_distance * 0.3)
	juke_point.y = global_position.y
	var final_point = global_position + (away_direction * this_dash_distance) + (perpendicular * -side * this_dash_distance * 0.3)
	final_point.y = global_position.y
	dash_waypoints = [juke_point, final_point]
	dash_waypoint_index = 0
	dash_target_position = dash_waypoints[0]
	state = State.DASH_AWAY
	can_dash = false
	dash_cooldown_timer.start()

func _do_dash_away():
	var direction = (dash_target_position - global_position)
	direction.y = 0
	var dist = direction.length()
	if dist < 1.0:
		dash_waypoint_index += 1
		if dash_waypoint_index < dash_waypoints.size():
			dash_target_position = dash_waypoints[dash_waypoint_index]
			return
		else:
			velocity.x = 0
			velocity.z = 0
			state = State.PLANT
			return
	direction = direction.normalized()
	velocity.x = direction.x * dash_speed
	velocity.z = direction.z * dash_speed
	var look_target = global_position + direction
	look_at(look_target, Vector3.UP)

func _move_to_ideal_range():
	var direction = (player.global_position - global_position).normalized()
	var dist = global_position.distance_to(player.global_position)
	if dist > ideal_range:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	elif dist < danger_range:
		velocity.x = -direction.x * move_speed * 0.5
		velocity.z = -direction.z * move_speed * 0.5
	else:
		velocity.x = move_toward(velocity.x, 0, 10 * 0.1)
		velocity.z = move_toward(velocity.z, 0, 10 * 0.1)

func _start_telegraph():
	state = State.TELEGRAPH
	can_attack = false
	await get_tree().create_timer(telegraph_time).timeout
	if state == State.TELEGRAPH and not is_dead:
		_ranged_attack()

func _ranged_attack():
	state = State.ATTACK
	attack_timer.start()
	# PROJECTILE LOGIC - TO BE ADDED LATER

func _on_attack_cooldown_done():
	can_attack = true
	if state == State.ATTACK:
		state = State.PLANT

func _on_death():
	state = State.IDLE
	await get_tree().create_timer(0.5).timeout
	queue_free()
