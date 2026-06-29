extends Panel

var ItemClass = preload("res://items/items.tscn")
var item = null
@onready var ghost_panel = %GhostSlot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_style()

func fit_item() -> void:
	item.position = Vector2.ZERO
	item.size = self.size
	#stretch texture rect tinside to fill
	var texture_rect = item.get_node("TextureRect")
	var label1 = item.get_node("Label")
	texture_rect.anchors_preset = Control.PRESET_FULL_RECT
	texture_rect.size = self.size
	label1.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	label1.size = self.size

##Places object owned by user and puts it into slot
func slot_place_item(held_item):
	ghost_panel.remove_child(held_item)
	add_child(held_item)
	self.item = ghost_panel.item
	ghost_panel.item = null
	refresh_style()
	
	
##Takes object owned by slot and gives it to user
func slot_take_item():
	self.remove_child(item)
	ghost_panel.add_child(item)
	ghost_panel.item = item
	self.item = null
	refresh_style()

func create_item(new_name, quantity): #can be used to create items
	item = ItemClass.instantiate()
	item.setup(new_name, quantity)
	add_child(item)
	fit_item()
	refresh_style()


func refresh_style():
	var stylebox = StyleBoxTexture.new()
	if item == null:
		stylebox.texture = load("res://inventory/inventoryslot.png")
	else:
		stylebox.texture = load("res://inventory/inventoryslotfill.png")
	add_theme_stylebox_override("panel", stylebox)
	print(stylebox)
