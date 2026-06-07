extends Node

const SlotClass = preload("res://inventory/scripts/slots.gd")
@onready var inventory_slots = $GridContainer1
@onready var ghost_panel = %GhostSlot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for inv_slots in inventory_slots.get_children():
		inv_slots.connect("gui_input", _slot_gui_input.bind(inv_slots))
	 # Replace with function body.

func _slot_gui_input(event: InputEvent, inv_slots: SlotClass) -> void:
	print("input received")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			print("Left clicked")
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
			if ghost_panel.item != null:
				if inv_slots.item != null:
					if ghost_panel.item.item_name == inv_slots.item.item_name and inv_slots.item.stack_size > inv_slots.item.item_quantity:
						print("Stacking...")
						ghost_panel.item.remove_item_quantity(1)
						inv_slots.item.add_item_quantity(1)
						if ghost_panel.item.item_quantity == 0:
							ghost_panel.remove_child(ghost_panel.item)
							ghost_panel.item = null
				else:
					if ghost_panel.item.item_quantity > 1:
						inv_slots.slot_mult_place(ghost_panel.item.item_name, 1)
						
						
				
					
				
				
				
