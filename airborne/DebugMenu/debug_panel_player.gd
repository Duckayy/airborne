# debug_panel_player.gd
# Attach to a Node inside the DebugMenu CanvasLayer
extends Node

var player: Node = null
var debug_menu: Node = null

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	debug_menu = get_parent()
	if debug_menu and debug_menu.has_method("register_panel"):
		debug_menu.register_panel("PLAYER", _build)

func _build(content: Control):
	if player == null:
		DebugMenu.make_label(content, "No player found!")
		return

	DebugMenu.make_label(content, "Movement", 15)

	var exports = {
		"Speed": ["speed", 0, 50],
		"Sprint Speed": ["sprint_speed", 0, 80],
		"Acceleration": ["acceleration", 0, 100],
		"Friction": ["friction", 0, 100],
		"Jump Velocity": ["jump_velocity", 0, 60],
		"Fall Acceleration": ["fall_acceleration", 0, 100],
		"Crouch Speed": ["crouch_speed", 0, 20],
		"Mouse Sensitivity": ["mouse_sensitivity", 0.001, 0.01],
	}

	for label in exports:
		var prop = exports[label][0]
		var min_val = exports[label][1]
		var max_val = exports[label][2]
		var current = player.get(prop)
		if current != null:
			DebugMenu.make_slider(content, label, min_val, max_val, current,
				func(val): player.set(prop, val)
			)

	DebugMenu.make_label(content, "Stamina", 15)

	var stamina_exports = {
		"Max Stamina": ["max_stamina", 0, 200],
		"Stamina Drain": ["stamina_drain", 0, 100],
		"Stamina Regen": ["stamina_regen", 0, 100],
	}

	for label in stamina_exports:
		var prop = stamina_exports[label][0]
		var min_val = stamina_exports[label][1]
		var max_val = stamina_exports[label][2]
		var current = player.get(prop)
		if current != null:
			DebugMenu.make_slider(content, label, min_val, max_val, current,
				func(val): player.set(prop, val)
			)

	DebugMenu.make_label(content, "Health", 15)

	var health_exports = {
		"Max Health": ["max_health", 0, 500],
	}

	for label in health_exports:
		var prop = health_exports[label][0]
		var min_val = health_exports[label][1]
		var max_val = health_exports[label][2]
		var current = player.get(prop)
		if current != null:
			DebugMenu.make_slider(content, label, min_val, max_val, current,
				func(val): player.set(prop, val)
			)

	DebugMenu.make_label(content, "Actions", 15)

	var god_state = {"enabled": false}
	var god_btn = DebugMenu.make_button(content, "God Mode: OFF", Color(0.4, 0.1, 0.1))
	god_btn.pressed.connect(func():
		god_state["enabled"] = !god_state["enabled"]
		god_btn.text = "God Mode: " + ("ON" if god_state["enabled"] else "OFF")
		if god_state["enabled"]:
			player.set("health", player.get("max_health"))
			player.set_meta("god_mode", true)
		else:
			player.set_meta("god_mode", false)
	)
	var heal_btn = DebugMenu.make_button(content, "Full Heal", Color(0.1, 0.4, 0.1))
	heal_btn.pressed.connect(func():
		player.set("health", player.get("max_health"))
		if player.has_node("HUD/HPBar"):
			player.get_node("HUD/HPBar").value = player.get("max_health")
	)
