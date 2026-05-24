extends CharacterBody3D

@export var speed = 14.0
@export var acceleration = 40.0
@export var friction = 12.0
@export var fall_acceleration = 60.0
@export var jump_velocity = 50.0
@export var mouse_sensitivity = 0.002

@onready var head = $Head

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("Move right"):
		input_dir.x += 1
	if Input.is_action_pressed("Move left"):
		input_dir.x -= 1
	if Input.is_action_pressed("Move forward"):
		input_dir.y += 1
	if Input.is_action_pressed("Move backwards"):
		input_dir.y -= 1

	input_dir = input_dir.normalized()

	var direction = (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	var target_velocity = direction * speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if input_dir == Vector2.ZERO:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= fall_acceleration * delta

	move_and_slide()
