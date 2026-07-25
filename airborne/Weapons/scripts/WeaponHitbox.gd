extends Node

@export var damage: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Swords/Area3D.body_entered.connect(_on_body_entered)
	pass # Replace with function body.

func setup(data) -> void:
	damage = data.Damage
	var mesh_scene: PackedScene = load(data.ModelPath)
	var mesh_instance = mesh_scene.instantiate()
	$Swords.add_child(mesh_instance)
	

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
