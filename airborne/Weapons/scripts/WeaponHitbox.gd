extends Node

@export var damage: int

@onready var area: Area3D = $Area3D
@onready var CollisionBox: CollisionShape3D = $Area3D/CollisionShape3D


var HitboxData = {}
var _active := false
var _already_hit: Dictionary = {} #Bodies already hit this swing
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area.monitoring = false
	area.body_entered.connect(_on_body_entered)
	HitboxData = JsonData.LoadData("res://Data/HitboxData.json")
	print(HitboxData)
	pass # Replace with function body.
	
func setup(data) -> void:
	damage = data["Damage"]
	var hitbox_key = data["Hitbox"]
	var hitbox_data = HitboxData[hitbox_key]
	change_dimensions(hitbox_data)
	change_position(hitbox_data)
	
func attack(active: bool) -> void:
	$Area3D.monitoring = active

func set_active(active: bool) -> void:
	_active = active
	area.set_deferred("monitoring", active) #For safe mid-physics
	if active:
		_already_hit.clear()
		
func _on_body_entered(body: Node3D) -> void:
	if not _active or body in _already_hit: #Prevents multiple hits in one swing
		return
	print("hit: ", body.name)
	print(body.name)
	print(body.get_class())
	print(body.get_groups())
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		print("Giving Damage")

func change_dimensions(data) -> void:
	CollisionBox.shape.size = Vector3(data["Dimensions"]["width"], data["Dimensions"]["height"], data["Dimensions"]["reach"])
	print("Current Hitbox Size:", CollisionBox.shape.size)

func change_position(data) -> void:
	CollisionBox.position = Vector3(data["Position"]["x"], data["Position"]["y"], data["Position"]["z"])
