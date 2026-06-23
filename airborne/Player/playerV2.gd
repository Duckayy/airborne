extends CharacterBody3D

@export var speed = 14.0
@export var sprint_speed = 35.0
@export var acceleration = 50.0
@export var friction = 60.0
@export var fall_acceleration = 60.0
@export var jump_velocity = 30.0
@export var mouse_sensitivity = 0.002
@export var max_stamina = 100.0
@export var stamina_drain = 30.0
@export var stamina_regen = 25.0
@export var stamina_recharge_delay = 3.0
@export var max_health = 100.0
@export var crouch_speed = 5.0
@export var crouch_height = 0.5

var is_crouching = false
var normal_height = 1.0
var stamina = max_stamina
var recharge_timer = 0.0
var health = max_health
var is_dead = false
var debug_open = false
var is_third_person = false

@onready var debug_menu = $HUD/DebugMenu
@onready var head = $Head
@onready var stamina_bar = $CanvasLayer/StaminaBar
@onready var hp_bar = $HUD/HPBar
@onready var death_screen = $HUD/DeathScreen
@onready var restart_button = $HUD/DeathScreen/RestartButton
@onready var quit_button = $HUD/DeathScreen/QuitButton
@onready var hp_label = $HUD/HPBar/HPLabel
@onready var first_person_camera = $Head/Camera3D
@onready var third_person_camera = $ThirdPersonPivot/ThirdPersonCamera
@onready var third_person_pivot = $ThirdPersonPivot


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina
	death_screen.visible = false
	hp_bar.max_value = max_health
	hp_bar.value = health
	restart_button.pressed.connect(_on_restart)
	quit_button.pressed.connect(_on_quit)
	debug_menu.visible = false
	_build_debug_menu()
	hp_bar.show_percentage = false
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(1.0, 0.0, 0.0, 1.0)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_label.text = str(int(health)) + " / " + str(int(max_health))
	hp_label.add_theme_color_override("font_color", Color.BLACK)
	
	# Stamina bar - green
	var stamina_fill = StyleBoxFlat.new()
	stamina_fill.bg_color = Color(0.0, 1.0, 0.0, 1.0)
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill)

	var stamina_bg = StyleBoxFlat.new()
	stamina_bg.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	stamina_bar.add_theme_stylebox_override("background", stamina_bg)
	stamina_bar.add_theme_color_override("font_color", Color.BLACK)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action("ui_cancel"):
			_toggle_debug()
			return
	if event is InputEventMouseMotion:
		if debug_open:
			return
		rotate_y(-event.relative.x * mouse_sensitivity)
		if is_third_person:
			third_person_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
			third_person_pivot.rotation.x = clamp(
				third_person_pivot.rotation.x,
				deg_to_rad(-80),
				deg_to_rad(80)
			)
		else:
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(
				head.rotation.x,
				deg_to_rad(-80),
				deg_to_rad(80)
			)
		
	if event.is_action_pressed("ToggleCamera"):
		is_third_person = !is_third_person
		if is_third_person:
			third_person_camera.current = true
		else:
			first_person_camera.current = true

func _physics_process(delta):
	if is_dead:
		return

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
	if Input.is_action_just_pressed("Crouch"):
		is_crouching = true
		$CollisionShape3D.shape.height = crouch_height
		head.position.y = 0.5
	elif Input.is_action_just_released("Crouch"):
		is_crouching = false
		$CollisionShape3D.shape.height = normal_height
		head.position.y = 1.0
		
	if is_crouching:
		current_speed = min(current_speed, crouch_speed)
		
	stamina = clamp(stamina, 0.0, max_stamina)
	stamina_bar.value = stamina

	var target_velocity = direction * current_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if input_dir == Vector2.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= fall_acceleration * delta

	move_and_slide()

func take_damage(amount: float):
	if is_dead:
		return
	health -= amount
	health = clamp(health, 0, max_health)
	hp_bar.value = health
	if health <= 0:
		_die()
	hp_label.text = str(int(health)) + " / " + str(int(max_health))

func _die():
	if is_dead:
		return
	is_dead = true
	death_screen.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart():
	is_dead = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _on_quit():
	get_tree().quit()
	
func _toggle_debug():
	debug_open = !debug_open
	debug_menu.visible = debug_open
	if debug_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_debug_menu():
	var vbox = $HUD/DebugMenu/ScrollContainer/VBoxContainer
	var title = Label.new()
	title.text = "DEBUG MENU"
	vbox.add_child(title)
	var exports = {
		"speed": "speed",
		"sprint_speed": "sprint_speed",
		"acceleration": "acceleration",
		"friction": "friction",
		"fall_acceleration": "fall_acceleration",
		"jump_velocity": "jump_velocity",
		"mouse_sensitivity": "mouse_sensitivity",
		"max_stamina": "max_stamina",
		"stamina_drain": "stamina_drain",
		"stamina_regen": "stamina_regen",
		"stamina_recharge_delay": "stamina_recharge_delay",
		"max_health": "max_health",
		"crouch_speed": "crouch_speed",
		"crouch_height": "crouch_height",
	}
	for label_text in exports:
		var prop = exports[label_text]
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = label_text
		lbl.custom_minimum_size.x = 200
		row.add_child(lbl)
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 200
		slider.value = get(prop)
		slider.custom_minimum_size.x = 150
		slider.value_changed.connect(func(val): set(prop, val))
		row.add_child(slider)
		var val_label = Label.new()
		val_label.text = str(get(prop))
		slider.value_changed.connect(func(val): val_label.text = str(snappedf(val, 0.01)))
		row.add_child(val_label)
		
		vbox.add_child(row)
	var quit_btn = Button.new()
	quit_btn.text = "Quit Game"
	quit_btn.pressed.connect(get_tree().quit)
	vbox.add_child(quit_btn)
