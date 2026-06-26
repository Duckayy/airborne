extends Node

const SlotClass = preload("res://inventory/scripts/slots.gd")
@onready var inventory_slots = $GridContainer1
@onready var ghost_panel = %GhostSlot
@onready var hotbar_slots = $HBoxContainer
var hide_screen = true
var save_data = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	 #Allows slots to accept input
	for inv_slots in inventory_slots.get_children():
		inv_slots.connect("gui_input", _slot_gui_input.bind(inv_slots))
	for hot_slots in hotbar_slots.get_children(): 
		hot_slots.connect("gui_input", _slot_gui_input.bind(hot_slots))
	load_inventory()
	
	$TextureRect.hide()
	$GridContainer1.hide()
	%GhostSlot.hide()

func _slot_gui_input(event: InputEvent, inv_slots: SlotClass) -> void:
	#print("input received")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			#print("Left clicked")
			"""Solution: 
				1. Check if user is holding item
				2. check if item in slot is same name AND won't hit max
				size if combined. If true then combine. Else then swap
				3. If user not holding item transfer to ghost
			"""
			#Holding item check
			if ghost_panel.item != null:
				if inv_slots.item == null:
					inv_slots.slot_place_item(ghost_panel.item)
				else: #swap slots
					ghost_panel.remove_child(ghost_panel.item)
					inv_slots.remove_child(inv_slots.item)
					ghost_panel.add_child(inv_slots.item)
					inv_slots.add_child(ghost_panel.item)
					var temp_item = inv_slots.item
					inv_slots.item = ghost_panel.item
					ghost_panel.item = temp_item
			elif inv_slots.item != null:
				inv_slots.slot_take_item()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			print("right click")
			if ghost_panel.item != null: #Holding Item Check
				if inv_slots.item != null:
					#check if item is same and doesnt exceed stack size
					if ghost_panel.item.item_name == inv_slots.item.item_name and inv_slots.item.stack_size > inv_slots.item.item_quantity:
						print("Stacking...")
						ghost_panel.item.remove_item_quantity(1)
						inv_slots.item.add_item_quantity(1)
						if ghost_panel.item.item_quantity == 0:
							ghost_panel.remove_child(ghost_panel.item)
							ghost_panel.item = null
				else:
					#Place single item into slot
					if ghost_panel.item.item_quantity > 1:
						inv_slots.create_item(ghost_panel.item.item_name, 1)
						ghost_panel.item.remove_item_quantity(1)
					else:
						inv_slots.slot_place_item(ghost_panel.item)

func _unhandled_key_input(event: InputEvent) -> void:
	
	#open and closes inventory
	if event.is_action_pressed("InventoryScreen"): 
		if hide_screen:
			$TextureRect.show()
			$GridContainer1.show()
			%GhostSlot.show()
			for hot_slots in hotbar_slots.get_children(): #Allows hotbar to be interacted
				hot_slots.mouse_filter = Control.MOUSE_FILTER_STOP
			hide_screen = false
		else:
			if ghost_panel.item != null:
				print("Item needs to be dropped to close menu")
				return
			$TextureRect.hide()
			$GridContainer1.hide()
			%GhostSlot.hide()
			for hot_slots in hotbar_slots.get_children(): #prevents hotbar to be interacted
				hot_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hide_screen = true
			


func save_inventory(): 
	var inv_index = -1
	for inv_slots in inventory_slots.get_children():
		var slot_data = {}
		inv_index = inv_index + 1
		if inv_slots.item == null:
			continue
		for property in inv_slots.item.get_property_list(): #gets attributes of itemclass
			if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE: #gets variables created in script of item.gd
				slot_data[property["name"]] = inv_slots.item.get(property["name"])
				slot_data["slot_index"] = inv_index
		print(slot_data)
		save_data.append(slot_data)
		# keep this one
	#for hot_slots in hotbar_slots:
		#save_data.append(hot_slots)
<<<<<<< Updated upstream
	#JsonData.SaveJSON("res://Data/Inventory/InventoryData.json", save_data)
=======
	print(save_data)
	JsonData.SaveJSON("res://Data/Inventory/InventoryData.json", save_data)
>>>>>>> Stashed changes
	
func load_inventory():
	save_data = JsonData.LoadData("res://Data/Inventory/InventoryData.json")
	
	for i in range(save_data.size()):
		var slot = inventory_slots.get_child(save_data[i]["slot_index"])

		slot.create_item(save_data[i]["item_name"], save_data[i]["item_quantity"])
	pass
