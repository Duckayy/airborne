class_name HitscanComponent
extends RayCast3D

@export var player: CollisionObject3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_exception(player)
	pass # Replace with function body.

func shoot() -> void:
	force_raycast_update()
	if is_colliding():
		var target := get_collider()
		print("Looking at: ", target.name)
		print("Hit point: ", get_collision_point())
	pass
