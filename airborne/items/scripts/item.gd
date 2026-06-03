extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if randi() % 2 == 0:	
		$TextureRect.texture = load("res://items/sword.png") # Replace with function body.
	else:
		$TextureRect.texture = load("res://items/hammer.png")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
