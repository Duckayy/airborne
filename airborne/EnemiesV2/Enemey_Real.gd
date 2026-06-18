extends CharacterBody3D

@export var max_health = 100.0
@export var move_speed = 6.0
@export var attack_range = 2.0
@export var attack_damage = 10.0
@export var attack_cooldown = 1.5
@export var detection_range = 20.0
@export var fall_acceleration = 60.0
@export var health_bar_visible_range = 10.0

var health = max_health
var player: Node3D = null
var can_attack = true
var has_taken_damage = false

@onready var attack_timer = $AttackTimer
@onready var health_bar_anchor = $HealthBarAnchor
@onready var health_bar_sprite = $HealthBarAnchor/HealthBarSprite
@onready var health_viewport = $HealthBarAnchor/HealthBarViewport
@onready var progress_bar = $HealthBarAnchor/HealthBarViewport/HealthProgressBar

enum State { IDLE, CHASE, ATTACK, DEAD }
var state = State.IDLE

func _ready():
	player = get_tree().get_first_node_in_group("player")
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_done)
	
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
	if state == State.DEAD:
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

func _update_health_bar_visibility():
	if player == null or not has_taken_damage:
		health_bar_anchor.visible = false
		return
	var dist = global_position.distance_to(player.global_position)
	health_bar_anchor.visible = dist <= health_bar_visible_range

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
	has_taken_damage = true
	health -= amount
	health = clamp(health, 0, max_health)
	progress_bar.value = health
	health_viewport.get_node("HPLabel").text = str(int(health)) + " / " + str(int(max_health))
	print("Enemy HP: ", health, " has_taken_damage: ", has_taken_damage)
	if health <= 0:
		_die()

func _die():
	state = State.DEAD
	health_bar_anchor.visible = false
	await get_tree().create_timer(0.5).timeout
	queue_free()
