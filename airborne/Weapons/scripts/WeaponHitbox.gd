extends Node

@export var damage: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
	pass # Replace with function body.

func setup(data) -> void:
	damage = data["Damage"]

func _on_body_entered(body: Node3D) -> void:
	print("hit: ", body.name)
	print(body.name)
	print(body.get_class())
	print(body.get_groups())
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Giving Damage")
