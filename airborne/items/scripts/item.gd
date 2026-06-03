extends Control

var item_name
var item_quantity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if randi() % 2 == 0:	
		$TextureRect.texture = load("res://items/sword.png") # Replace with function body.
	else:
		$TextureRect.texture = load("res://items/hammer.png")
	var stack_size = int(JsonData.item_data[item_name]["StackSize"])
	item_quantity = randi() % stack_size + 1
	
	if stack_size == 1:
		$Label.visible = false
	else:
		$Label.text = String(item_quantity)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
