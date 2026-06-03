extends CharacterBody3D

@export var max_health = 100.0
@export var move_speed = 6.0
@export var attack_range = 2.0
@export var attack_damage = 10.0
@export var attack_cooldown = 1.5
@export var detection_range = 20.0
@export var fall_acceleration = 60.0

var health = max_health
var player: Node3D = null
var can_attack = true

@onready var attack_timer = $AttackTimer

enum State { IDLE, CHASE, ATTACK, DEAD }
var state = State.IDLE

func _ready():
	player = get_tree().get_first_node_in_group("player")
	print("Player found: ", player)  # add this line
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_done)

func _physics_process(delta):
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= fall_acceleration * delta

	_update_state()

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
				_attack()

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
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

func _attack():
	can_attack = false
	attack_timer.start()
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

func _on_attack_cooldown_done():
	can_attack = true

func take_damage(amount: float):
	if state == State.DEAD:
		return
	health -= amount
	if health <= 0:
		_die()

func _die():
	state = State.DEAD
	await get_tree().create_timer(0.5).timeout
	queue_free()
