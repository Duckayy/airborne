class_name Cooldown
extends Timer

signal started #signal on of cooldown started

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	one_shot = true
	autostart = false
	pass # Replace with function body.

func try_start() -> bool:
	if not is_stopped():
		return false
	start()
	started.emit()
	return true
