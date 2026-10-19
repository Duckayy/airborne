extends StaticBody3D

@export var npc_name = "Merchant"
@export var starting_coins = 200

var player_in_range = false
var player: Node = null
var shop_ui: Node = null
var interact_label: Label3D = null
var coins: int = 0
var purchased_levels: Dictionary = {}

@onready var interact_area = $InteractArea

func _ready():
	coins = starting_coins
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_make_interact_label()

func _make_interact_label():
	interact_label = Label3D.new()
	interact_label.text = "Press F to shop"
	interact_label.font_size = 28
	interact_label.modulate = Color(1.0, 0.85, 0.3)
	interact_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interact_label.position = Vector3(0, 2.5, 0)
	interact_label.visible = false
	add_child(interact_label)

func _physics_process(_delta):
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	interact_label.visible = dist <= 8.0 and shop_ui == null
	player_in_range = dist <= 3.0
	if dist > 3.5 and shop_ui != null:
		_close_shop()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			if shop_ui != null:
				_close_shop()
			elif player_in_range:
				_open_shop()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		player_in_range = false
		_close_shop()

func _open_shop():
	if shop_ui != null:
		return
	if player:
		player.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var canvas = CanvasLayer.new()
	canvas.name = "ShopCanvas"
	canvas.layer = 15
	get_tree().current_scene.add_child(canvas)

	shop_ui = load("res://NPCs/Trader NPC/shop_ui.gd").new()
	canvas.add_child(shop_ui)
	shop_ui.open(player, coins, purchased_levels)
	shop_ui.shop_closed.connect(_close_shop)

func _close_shop():
	if shop_ui == null:
		return
	coins = shop_ui.coins
	purchased_levels = shop_ui.purchased_levels
	if player:
		player.set_process_unhandled_input(true)
	var canvas = get_tree().current_scene.get_node_or_null("ShopCanvas")
	if canvas:
		canvas.queue_free()
	shop_ui = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
