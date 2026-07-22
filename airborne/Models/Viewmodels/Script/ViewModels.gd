extends Node

var inventory_data = JsonData.LoadData("res://Data/Inventory/InventoryData.json")
var item_data = JsonData.LoadData("res://Data/ItemData.json")
var item_asset_data = JsonData.LoadData("res://Data/ItemAssetData.json")

@onready var player = $"../../.."
@onready var model = $SubViewportContainer/SubViewport/Swords
@onready var animation = $SubViewportContainer/SubViewport/Swords/AnimationPlayer

var current_instance: Node3D = null
var lib := AnimationLibrary.new()
var item_resources = {}
var item_animation = {}
var current_item = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_item_models()
	load_item_animations()
	player.item_model.connect(load_model)
	pass # Replace with function body.

func load_item_models():
	for item in item_asset_data:
		var item_path = item_asset_data[item]["ModelPath"]
		item_resources[item] = load(item_path)

func load_item_animations():
	for item in item_asset_data:
		var ani = load(item_asset_data[item]["UseAnimation"])
		lib.add_animation(item, ani)
	animation.add_animation_library("UseAnimation", lib)
	

func load_model(model_id):
	if current_instance != null:
		current_instance.queue_free()
		current_instance = null
	if model_id != null:
		var scene: PackedScene = item_resources[model_id]
		current_instance = scene.instantiate()
		model.add_child(current_instance)
	current_item = model_id
	
func play_animation():
	#animation.play(item_asset_data[]["UseAnimation"])
	if current_item != null:
		animation.play("UseAnimation/" + current_item)
	pass
