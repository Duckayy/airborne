extends BaseEnemy

@export var move_speed = 6.0
@export var attack_range = 4.0

@onready var attack_timer = $AttackTimer

enum State { IDLE, CHASE, ATTACK, DEAD }
var state = State.IDLE

func _enemy_ready():
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func(): can_attack = true)

func _physics_process(delta):
	if is_dead:
		return
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	_update_state()
	_update_health_bar_visibility()
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
		State.CHASE:
			_chase()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
			if can_attack:
				_melee_attack()
	move_and_slide()

func _update_state():
	if player == null:
		state = State.IDLE
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_range:
		state = State.ATTACK
	elif dist <= detection_range:
		state = State.CHASE
	else:
		state = State.IDLE

func _chase():
	if player == null:
		return
	# Recalculate direction every frame toward current player position
	var direction = (player.global_position - global_position)
	direction.y = 0  # ignore height difference so they don't float up
	direction = direction.normalized()
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Face the player
	var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	if look_target != global_position:
		look_at(look_target, Vector3.UP)

func _melee_attack():
	can_attack = false
	attack_timer.start()
	_do_attack()

func _on_death():
	state = State.DEAD
	await get_tree().create_timer(0.5).timeout
	queue_free()
