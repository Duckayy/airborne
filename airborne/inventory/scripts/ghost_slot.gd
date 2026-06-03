extends Panel

var ItemClass = preload("res://items/items.tscn")
var item = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func fit_item() -> void:
	item.position = Vector2.ZERO
	item.size = self.size
	
	#stretch texture rect tinside to fill
	var texture_rect = item.get_node("TextureRect")
	texture_rect.anchors_preset = Control.PRESET_FULL_RECT
	texture_rect.size = self.size
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.position = get_global_mouse_position() - size / 4
