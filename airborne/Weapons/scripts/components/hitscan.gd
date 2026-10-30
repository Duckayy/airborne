class_name HitscanComponent
extends RayCast3D

signal hit(collider: Object, point: Vector3)
signal missed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot() -> void:
	force_raycast_update()
	if is_colliding():
		var target := get_collider()
		var target_point := get_collision_point()
		print("Looking at: ", target.name)
		print("Hit point: ", target_point)
		hit.emit(target, target_point)
	else:
		missed.emit()
	pass
