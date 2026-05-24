extends Panel

var ItemClass = preload("res://items/items.tscn")
var item = null

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
	texture_rect.anchors_preset = Control.PRESET_FULL_RECT
	texture_rect.size = self.size
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
