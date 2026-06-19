extends Control

var item_name
var item_quantity
var item_category
var slot_index

func setup(i_name, i_quantity) -> void:
	item_name = i_name
	item_quantity = i_quantity
	$TextureRect.texture = load("res://items/" + item_name + ".png")
	var stack_size = int(JsonData.item_data[item_name]["StackSize"])
	item_category = String(JsonData.item_data[item_name]["ItemCategory"])
	if item_quantity == null:
		item_quantity = randi() % stack_size + 1
	if stack_size == 1:
		$Label.visible = false
	else:
		$Label.text = str(item_quantity)
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#randomizes what item object is
	if item_name == null:
		if randi() % 2 == 0:	
			item_name = "Sword" 
		else:
			item_name = "Hammer"
	setup(item_name, item_quantity)

func add_item_quantity(amount_to_add):
	item_quantity += amount_to_add
	$Label.text = str(item_quantity)
	
func remove_item_quantity(amount_to_remove):
	item_quantity -= amount_to_remove
	$Label.text = str(item_quantity)
