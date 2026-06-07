extends Control

var item_name
var item_quantity
var stack_size

func setup() -> void:
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#randomizes what item object is
	if item_name == null:
		if randi() % 2 == 0:	
			item_name = "Sword" 
		else:
			item_name = "Hammer"
	$TextureRect.texture = load("res://items/" + item_name + ".png")
	stack_size = int(JsonData.item_data[item_name]["StackSize"])
	if item_quantity == null:
		item_quantity = randi() % stack_size + 1
	if stack_size == 1:
		$Label.visible = false
	else:
		$Label.text = str(item_quantity)

func add_item_quantity(amount_to_add):
	item_quantity += amount_to_add
	$Label.text = str(item_quantity)
	
func remove_item_quantity(amount_to_remove):
	item_quantity -= amount_to_remove
	$Label.text = str(item_quantity)
