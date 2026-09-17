extends Control

signal closed
signal trade_requested

var dialogue_lines: Array = []
var current_line = 0 
var can_trade = false
var overlay = ColorRect.new()

@onready var npc_name_label = $DialogueBox/MarginContainer/VBoxContainer/NPCNameLabel
@onready var dialogue_text = $DialogueBox/MarginContainer/VBoxContainer/DialogueText
@onready var next_button = $DialogueBox/MarginContainer/VBoxContainer/HBoxContainer/NextButton
@onready var trade_button = $DialogueBox/MarginContainer/VBoxContainer/HBoxContainer/TradeButton
@onready var close_button = $DialogueBox/MarginContainer/VBoxContainer/HBoxContainer/CloseButton

func _ready():
	next_button.pressed.connect(_on_next)
	trade_button.pressed.connect(func(): emit_signal("trade_requested"))
	close_button.pressed.connect(func(): emit_signal("closed"))
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	move_child(overlay, 0)
	# Remove default panel background
	var empty_style = StyleBoxEmpty.new()
	$DialogueBox.add_theme_stylebox_override("panel", empty_style)
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -150
	offset_bottom = 0
	offset_left = 0
	offset_right = 0

# Add styled background only to the dialogue box
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	$DialogueBox.add_theme_stylebox_override("panel", panel_style)
	
func setup(npc_name: String, lines: Array, trading: bool):
	dialogue_lines = lines
	can_trade = trading
	npc_name_label.text = npc_name
	trade_button.visible = false
	_show_line(0)
	
func _show_line(index: int):
	current_line = index
	dialogue_text.text = dialogue_lines[index]
	if index >= dialogue_lines.size() -1:
		next_button.visible = false
		trade_button.visible = can_trade
	else:
		next_button.visible = true
		trade_button.visible = false
		
func _on_next():
	if current_line < dialogue_lines.size() - 1:
		_show_line(current_line +1)
