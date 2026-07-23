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

@onready var interact_area = $InteractArea

signal trade_requested

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_create_interact_label()

func _create_interact_label():
	var label_3d = Label3D.new()
	label_3d.name = "InteractLabel"
	label_3d.text = "Press E to interact"
	label_3d.font_size = 32
	label_3d.modulate = Color.YELLOW
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.position = Vector3(0, 2.5, 0)
	label_3d.visible = false
	add_child(label_3d)
	interact_label = label_3d

func _unhandled_input(event):
	if not player_in_range:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			_open_dialogue()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		if interact_label:
			interact_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		player_in_range = false
		if interact_label:
			interact_label.visible = false
		_close_dialogue()

func _open_dialogue():
	if dialogue_ui != null:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dialogue_ui = load("res://NPCs/NPC1/DialogueUI.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_ui)
	dialogue_ui.setup(npc_name, dialogue, can_trade)
	dialogue_ui.closed.connect(_close_dialogue)
	dialogue_ui.trade_requested.connect(func(): emit_signal("trade_requested"))

func _close_dialogue():
	if dialogue_ui == null:
		return
	dialogue_ui.queue_free()
	dialogue_ui = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
