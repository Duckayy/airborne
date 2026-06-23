extends CharacterBody3D

@export var max_health = 100.0
@export var move_speed = 6.0
@export var ideal_range = 12.0
@export var min_range = 6.0
@export var max_range = 18.0
#@export var attack_damage = 10.0
@export var attack_cooldown = 2
@export var detection_range = 25.0
@export var fall_acceleration = 60.0
@export var health_bar_visible_range = 10.0
@export var reposition_interval = 3.0
@export var strafe_speed = 4.0

var health = max_health
var player: Node3D = null
var can_attack = true
var has_line_of_sight = false
var strafe_direction = 1

@onready var attack_timer = $AttackTimer
@onready var reposition_timer = $RepositionTimer
@onready var los_ray = $LineOfSightRay

enum State { IDLE, REPOSITION, STRAFE, ATTACK, RETREAT, DEAD }
var state = State.IDLE

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_done)
	
	reposition_timer.wait_time = reposition_interval
	reposition_timer.one_shot = false
	reposition_timer.timeout.connect(_on_reposition_timer)
	reposition_timer.start()
	
func _physics_process(delta):
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y -= fall_acceleration *delta
		
	_check_line_of_sight()
	_update_state()
	
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
		State.REPOSITION:
			_move_to_ideal_range()
		State.STRAFE:
			_strafe()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
			if can_attack and has_line_of_sight:
				_attack()
		State.RETREAT:
			_retreat()
			
	if player: #Always face the player when not dead
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
		var collider = los_ray.get_collider()
		has_line_of_sight = collider == player
	else:
		has_line_of_sight = false
	
func _update_state():
	if player == null:
		state = State.IDLE
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	if dist > detection_range:
		state = State.IDLE
		return
		
	if dist < min_range:
		state = State.RETREAT
	elif dist > max_range:
		state = State.REPOSITION
	elif has_line_of_sight:
		state = State.ATTACK
	else:
		state = State.STRAFE
		
func _move_to_ideal_range():
	var direction = (player.global_position - global_position).normalized()
	var dist = global_position.distance_to(player.global_position)
	
	if dist > ideal_range:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, 10 * 0.1)
		velocity.z = move_toward(velocity.z, 0, 10 * 0.1)

func _strafe():
	# Moves sideways relative to player to try to regain line of sight
	var to_player = (player.global_position - global_position).normalized()
	var strafe_dir = to_player.cross(Vector3.UP) * strafe_direction
	velocity.x = strafe_dir.x * strafe_speed
	velocity.z = strafe_dir.z * strafe_speed

func _retreat():
	var direction = (global_position - player.global_position).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

func _attack():
	can_attack = false
	attack_timer.start()
	# PROJECTILE LOGIC - TO BE ADDED LATER
	# var projectile = preload("res://Projectiles/Projectile.tscn").instantiate()
	# get_tree().current_scene.add_child(projectile)
	# projectile.global_position = global_position + Vector3.UP
	# projectile.direction = (player.global_position - global_position).normalized()
	print("Ranged enemy attacks! (projectile logic pending)")

func _on_attack_cooldown_done():
	can_attack = true

func _on_reposition_timer():
	# Randomly flip strafe direction periodically for unpredictability
	strafe_direction *= -1

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

		
