extends StaticBody3D

@export var npc_name = "Villager"
@export var can_trade = false
@export var dialogue: Array[String] = [
	"Hello traveller!",
	"It's dangerous out there.",
	"Be careful of the enemies nearby.",
]

var player_in_range = false
var player: Node3D = null
var dialogue_ui = null
var interact_label = null
var player_in_label_range = false


@onready var interact_area = $InteractArea

signal trade_requested

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_create_interact_label()

func _physics_process(_delta):
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	
	# Show label at 8m
	if dist <= 8.0:
		if interact_label:
			interact_label.visible = true
	else:
		if interact_label:
			interact_label.visible = false
	
	# Only allow interaction at 3m
	player_in_range = dist <= 3.0
	
	# Close dialogue if player walks away
	if dist > 3.0 and dialogue_ui != null:
		_close_dialogue()

func _create_interact_label():
	var label_3d = Label3D.new()
	label_3d.name = "InteractLabel"
	label_3d.text = "Press F to interact"
	label_3d.font_size = 32
	label_3d.modulate = Color.YELLOW
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.position = Vector3(0, 2.5, 0)
	label_3d.visible = false
	add_child(label_3d)
	interact_label = label_3d

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			if dialogue_ui != null:
				_close_dialogue()
			elif player_in_range:
				_open_dialogue()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		player_in_range = false
		_close_dialogue()

func _open_dialogue():
	if dialogue_ui != null:
		return
	# Only disable camera/mouse look, not full physics
	if player:
		player.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	canvas.name = "DialogueCanvas"
	get_tree().current_scene.add_child(canvas)
	
	
	dialogue_ui = load("res://NPCs/NPC1/DialogueUI.tscn").instantiate()
	dialogue_ui.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_ui.offset_top = -150
	dialogue_ui.offset_bottom = 0
	dialogue_ui.offset_left = 0
	dialogue_ui.offset_right = 0
	canvas.add_child(dialogue_ui)
	dialogue_ui.setup(npc_name, dialogue, can_trade)
	dialogue_ui.closed.connect(_close_dialogue)
	dialogue_ui.trade_requested.connect(func(): emit_signal("trade_requested"))
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.anchor_left = 0
	overlay.anchor_top = 0
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	
	if interact_label:
		interact_label.visible = false

func _close_dialogue():
	if dialogue_ui == null:
		return
	if player:
		player.set_process_unhandled_input(true)
	var canvas = get_tree().current_scene.get_node_or_null("DialogueCanvas")
	if canvas:
		canvas.queue_free()
	dialogue_ui = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if interact_label and player_in_range:
		interact_label.visible = true
