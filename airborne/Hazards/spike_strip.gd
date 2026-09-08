extends Area3D

@export var damage_per_tick = 10.0
@export var tick_interval = 1.0

var bodies_in_zone = []
var tick_timer = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta):
	if bodies_in_zone.is_empty():
		return

	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_damage_bodies()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		if not bodies_in_zone.has(body):
			bodies_in_zone.append(body)
			# Optional: damage immediately on entry too
			body.take_damage(damage_per_tick)

func _on_body_exited(body):
	if bodies_in_zone.has(body):
		bodies_in_zone.erase(body)

func _damage_bodies():
	for body in bodies_in_zone:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
