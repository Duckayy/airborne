extends CharacterBody3D

@export var speed = 14.0
@export var sprint_speed = 35.0
@export var acceleration = 50.0
@export var friction = 50.0

@export var fall_acceleration = 60.0
@export var jump_velocity = 30.0

@export var mouse_sensitivity = 0.002

@export var max_stamina = 100.0
@export var stamina_drain = 30.0
@export var stamina_regen = 25.0
@export var stamina_recharge_delay = 3.0

var stamina = max_stamina
var recharge_timer = 0.0

@onready var head = $Head
@onready var stamina_bar = $CanvasLayer/StaminaBar

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		head.rotate_x(-event.relative.y * mouse_sensitivity)

		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-80),
			deg_to_rad(80)
		)

func _physics_process(delta):

	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("Move Right"):
		input_dir.x += 1

	if Input.is_action_pressed("Move Left"):
		input_dir.x -= 1

	if Input.is_action_pressed("Move Forward"):
		input_dir.y += 1

	if Input.is_action_pressed("Move Backward"):
		input_dir.y -= 1

	input_dir = input_dir.normalized()

	var direction = (
		transform.basis *
		Vector3(input_dir.x, 0, -input_dir.y)
	).normalized()

	var current_speed = speed

	if Input.is_action_pressed("Sprint") and stamina > 0 and input_dir != Vector2.ZERO:
		current_speed = sprint_speed
		stamina -= stamina_drain * delta
		recharge_timer = stamina_recharge_delay
	else:
		if recharge_timer > 0:
			recharge_timer -= delta
		else:
			stamina += stamina_regen * delta

	stamina = clamp(stamina, 0.0, max_stamina)
	stamina_bar.value = stamina

	var target_velocity = direction * current_speed

	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		acceleration * delta
	)

	if input_dir == Vector2.ZERO:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			friction * delta
		)

	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= fall_acceleration * delta

	move_and_slide()
