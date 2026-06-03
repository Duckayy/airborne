extends Control

var item_name
var item_quantity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if randi() % 2 == 0:	
		item_name = "Sword" # Replace with function body.
	else:
		item_name = "Hammer"
	$TextureRect.texture = load("res://items/" + item_name + ".png")
	var stack_size = int(JsonData.item_data[item_name]["StackSize"])
	item_quantity = randi() % stack_size + 1
	
	if stack_size == 1:
		$Label.visible = false
	else:
		$Label.text = str(item_quantity)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
