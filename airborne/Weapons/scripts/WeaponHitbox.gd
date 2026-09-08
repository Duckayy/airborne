extends Node

@export var damage: int

@onready var CollisionBox = $Area3D/CollisionShape3D

var HitboxData = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
	HitboxData = JsonData.LoadData("res://Data/HitboxData.json")
	print(HitboxData)
	pass # Replace with function body.

func setup(data) -> void:
	damage = data["Damage"]
	var hitbox_key = data["Hitbox"]
	var hitbox_data = HitboxData[hitbox_key]
	change_dimensions(hitbox_data)
	change_position(hitbox_data)
	

func _on_body_entered(body: Node3D) -> void:
	print("hit: ", body.name)
	print(body.name)
	print(body.get_class())
	print(body.get_groups())
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Giving Damage")

func change_dimensions(data) -> void:
	CollisionBox.shape.size = Vector3(data["Dimensions"]["width"], data["Dimensions"]["height"], data["Dimensions"]["reach"])
	print("Current Hitbox Size:", CollisionBox.shape.size)

func change_position(data) -> void:
	CollisionBox.position = Vector3(data["Position"]["x"], data["Position"]["y"], data["Position"]["z"])
