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
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _gui_input(event: InputEvent) -> void:
	print("input received")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			print("Left clicked")
			if item != null: #if item exists 
				remove_child(item)
				if ghost_panel.item != null:
					ghost_panel.remove_child(ghost_panel.item)
					ghost_panel.add_child(item)
					add_child(ghost_panel.item)
					var temp = item
					item = ghost_panel.item
					ghost_panel.item = temp
				else:
					ghost_panel.add_child(item)
					ghost_panel.item = item
					item = null
				print("ghost has: ", ghost_panel.item)
			elif ghost_panel.item != null: #if cursor slot already has item
				print("dropping item")
				item = ghost_panel.item
				ghost_panel.remove_child(item)
				add_child(item)
				ghost_panel.item = null
