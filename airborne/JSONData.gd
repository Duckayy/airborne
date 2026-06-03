extends Node

var item_data: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_data = LoadData("res://Data/ItemData.json")
 # Replace with function body.

func LoadData(file_path):
	if FileAccess.file_exists(file_path):
		var json_data
		var json_text
		var file_data = FileAccess.open(file_path, FileAccess.READ)
		#turns file into string then into dictionary
		json_text = file_data.get_as_text() 
		print(json_text)
		json_data = JSON.parse_string(json_text) 
		file_data.close()
		return json_data
	else:
		print("File not found")
		return {} #{} better than null as it prevents future crashes
