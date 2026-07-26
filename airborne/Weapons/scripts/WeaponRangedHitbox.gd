extends Node

var damage: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup(data) -> void:
	damage = data["Damage"]
	var mesh_scene: PackedScene = load(data["ModelPath"])
	var mesh_instance = mesh_scene.instantiate()
	$Model.add_child(mesh_instance)
# Called every frame. 'delta' is the elapsed time since the previous frame.
