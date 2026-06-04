extends Panel

var ItemClass = preload("res://items/items.tscn")
var item = null
@onready var ghost_panel = %GhostSlot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if randi() % 2 == 0:
		item = ItemClass.instantiate()
		add_child(item) # Replace with function body.
		fit_item()

func fit_item() -> void:
	item.position = Vector2.ZERO
	item.size = self.size
	#stretch texture rect tinside to fill
	var texture_rect = item.get_node("TextureRect")
	var label1 = item.get_node("Label")
	texture_rect.anchors_preset = Control.PRESET_FULL_RECT
	texture_rect.size = self.size
	print("control size: ", self.size)
	print("label size: ", label1.size)
	print("label position: ", label1.position)
	label1.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	label1.size = self.size / 4

##Places object owned by user and puts it into slot
func slot_place_item(held_item):
	ghost_panel.remove_child(held_item)
	add_child(held_item)
	self.item = ghost_panel.item
	ghost_panel.item = null
	
	
##Takes object owned by slot and gives it to user
func slot_take_item():
	self.remove_child(item)
	ghost_panel.add_child(item)
	ghost_panel.item = item
	self.item = null

func slot_mult_place():
	ghost_panel.item.remove_item_quantity(1)
	ItemClass.instantiate()
	add_child(item)
	fit_item()
	self.item = ghost_panel.item
	item.add_item_quantity(1)
