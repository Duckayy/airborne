extends Node

var inventory_data = JsonData.LoadData("res://Data/Inventory/InventoryData.json")
var item_data = JsonData.LoadData("res://Data/ItemData.json")

@onready var player = $"../../.."

var item_resources = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_item_models()
	player.item_model.connect(load_model)
	pass # Replace with function body.

func load_item_models():
	for item in item_data:
		var item_path = item_data[item]["ModelPath"]
		item_resources[item] = load(item_path)
		
func load_model(model_id):
	if model_id != null:
		self.texture = item_resources[model_id]
	else:
		self.texture = null
	print(self.texture)
