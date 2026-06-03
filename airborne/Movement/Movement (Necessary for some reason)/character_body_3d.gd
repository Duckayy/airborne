extends CharacterBody3D

@export var speed = 14.0
@export var fall_acceleration = 75.0

func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("Move right"):
		direction.x += 1
	if Input.is_action_pressed("Move left"):
		direction.x -= 1

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		velocity.y = 0

	move_and_slide()
