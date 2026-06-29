extends Node

var item_data: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_data = LoadData("res://Data/ItemData.json")
	
 # Replace with function body.

func LoadData(file_path):
	if FileAccess.file_exists(file_path):
		var json_text
		var file_data = FileAccess.open(file_path, FileAccess.READ)
		#turns file into string then into dictionary
		json_text = file_data.get_as_text() 
		var json_data = JSON.parse_string(json_text) 
		file_data.close()
		return json_data
	else:
		print("File not found")
		return {} #{} better than null as it prevents future crashes
		
func SaveJSON(path: String, data: Variant) -> void:
	# 1. Convert data to a JSON string
	var json_string = JSON.stringify(data, "\t") # "\t" adds indentation for readability
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		print("Error opening file: ", path)

		
