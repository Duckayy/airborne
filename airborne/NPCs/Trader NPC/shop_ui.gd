extends CanvasLayer

signal shop_closed

var player: Node = null
var coins: int=0
var purchased_levels: Dictionary = {}

var coin_label: Label = null
var upgrade_list: VBoxContainer = null

func _ready():
	layer = 15
	_build_ui()
	
func _build_ui():
	#root control
	var root = Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	#Dark tinted overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0.0,0.0,0.0,0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	
	#Main panel
	var panel = PanelContainer.new()
	panel.name = "Panel"
	var panel_style = StyleBoxFlat.new()
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.3, 0.3, 0.35)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.set_anchor(SIDE_LEFT,0.5)
	panel.set_anchor(SIDE_RIGHT,0.5)
	panel.set_anchor(SIDE_TOP,0.5)
	panel.set_anchor(SIDE_BOTTOM,0.5)
	panel.offset_left = -290
	panel.offset_right = 290
	panel.offset_top = -240
	panel.offset_bottom = 240
	root.add_child(panel)
	
	#Outer margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("seperation", 8)
	margin.add_child(outer_vbox)
	
	#Header row
	var header = HBoxContainer.new()
	outer_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Shop"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	header.add_child(title)
	
	coin_label = Label.new()
	coin_label.add_theme_font_size_override("font_size", 15)
	coin_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(coin_label)
	
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.add_theme_font_size_override("font_size", 16)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.4, 0.1, 0.1)
	close_style.corner_radius_top_left = 5
	close_style.corner_radius_top_right = 5
	close_style.corner_radius_bottom_left = 5
	close_style.corner_radius_bottom_right = 5
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	# Divider
	var sep = HSeparator.new()
	outer_vbox.add_child(sep)

	# Hint label
	var hint = Label.new()
	hint.text = "Press F or any movement key to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(hint)

	# Scroll area for upgrades
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	upgrade_list = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 6)
	upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(upgrade_list)

	_build_upgrades()

func open(p: Node, current_coins: int, levels: Dictionary):
	player = p
	coins = current_coins
	purchased_levels = levels
	visible = true
	_refresh()

func _close():
	visible = false
	emit_signal("shop_closed")

func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		var exit_keys = [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_F]
		if event.keycode in exit_keys:
			_close()

func _build_upgrades():
	for upgrade in ShopData.UPGRADES:
		upgrade_list.add_child(_make_row(upgrade))

func _make_row(upgrade: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.name = upgrade["id"]
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.14, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.22, 0.22, 0.28)
	container.add_theme_stylebox_override("panel", style)
	container.custom_minimum_size.y = 68

	var row_margin = MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", 10)
	row_margin.add_theme_constant_override("margin_right", 10)
	row_margin.add_theme_constant_override("margin_top", 6)
	row_margin.add_theme_constant_override("margin_bottom", 6)
	container.add_child(row_margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row_margin.add_child(hbox)

	# Left — name + description
	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	hbox.add_child(text_box)

	var name_lbl = Label.new()
	name_lbl.text = upgrade["name"]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	text_box.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = upgrade["description"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_box.add_child(desc_lbl)

	# Right — level + buy button
	var right_box = VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 4)
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_box)

	var level_lbl = Label.new()
	level_lbl.name = "LevelLbl"
	level_lbl.add_theme_font_size_override("font_size", 11)
	level_lbl.add_theme_color_override("font_color", Color(0.45, 0.8, 0.55))
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_box.add_child(level_lbl)

	var buy_btn = Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.custom_minimum_size = Vector2(105, 30)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	right_box.add_child(buy_btn)

	var captured = upgrade.duplicate()
	buy_btn.pressed.connect(func(): _buy(captured))

	return container

func _buy(upgrade: Dictionary):
	var id = upgrade["id"]
	var level = purchased_levels.get(id, 0)

	if level >= upgrade["max_level"]:
		return

	var cost = upgrade["cost"] + (level * int(upgrade["cost"] * 0.5))

	if coins < cost:
		# Flash the button red briefly
		var container = upgrade_list.get_node_or_null(id)
		if container:
			var btn = _find_buy_btn(container)
			if btn:
				_flash_red(btn)
		return

	coins -= cost
	purchased_levels[id] = level + 1

	if player and player.get(upgrade["stat"]) != null:
		player.set(upgrade["stat"], player.get(upgrade["stat"]) + upgrade["amount"])
		# Also update max health/stamina values on the player bars
		if upgrade["stat"] == "max_health":
			player.health = min(player.health + upgrade["amount"], player.max_health)
			if player.has_node("HUD/HPBar"):
				player.get_node("HUD/HPBar").max_value = player.max_health
				player.get_node("HUD/HPBar").value = player.health
		if upgrade["stat"] == "max_stamina":
			if player.has_node("CanvasLayer/StaminaBar"):
				player.get_node("CanvasLayer/StaminaBar").max_value = player.max_stamina

	_refresh()

func _find_buy_btn(container: Node) -> Button:
	for child in container.get_children():
		var result = _find_buy_btn_recursive(child)
		if result:
			return result
	return null

func _find_buy_btn_recursive(node: Node) -> Button:
	if node is Button and node.name == "BuyBtn":
		return node
	for child in node.get_children():
		var result = _find_buy_btn_recursive(child)
		if result:
			return result
	return null

func _flash_red(btn: Button):
	var flash = StyleBoxFlat.new()
	flash.bg_color = Color(0.7, 0.1, 0.1)
	flash.corner_radius_top_left = 5
	flash.corner_radius_top_right = 5
	flash.corner_radius_bottom_left = 5
	flash.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("normal", flash)
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(btn):
		_refresh()

func _refresh():
	if coin_label:
		coin_label.text = "  Coins: " + str(coins)

	for upgrade in ShopData.UPGRADES:
		var id = upgrade["id"]
		var level = purchased_levels.get(id, 0)
		var container = upgrade_list.get_node_or_null(id)
		if container == null:
			continue

		var buy_btn = _find_buy_btn(container)
		var level_lbl = container.find_child("LevelLbl", true, false)

		if level_lbl:
			level_lbl.text = "Lv " + str(level) + " / " + str(upgrade["max_level"])

		if buy_btn:
			if level >= upgrade["max_level"]:
				buy_btn.text = "MAXED"
				buy_btn.disabled = true
				var s = StyleBoxFlat.new()
				s.bg_color = Color(0.22, 0.22, 0.22)
				s.corner_radius_top_left = 5
				s.corner_radius_top_right = 5
				s.corner_radius_bottom_left = 5
				s.corner_radius_bottom_right = 5
				buy_btn.add_theme_stylebox_override("normal", s)
			else:
				var cost = upgrade["cost"] + (level * int(upgrade["cost"] * 0.5))
				buy_btn.text = str(cost) + " coins"
				buy_btn.disabled = false
				var can_afford = coins >= cost
				var s = StyleBoxFlat.new()
				s.bg_color = Color(0.15, 0.4, 0.2) if can_afford else Color(0.28, 0.12, 0.12)
				s.corner_radius_top_left = 5
				s.corner_radius_top_right = 5
				s.corner_radius_bottom_left = 5
				s.corner_radius_bottom_right = 5
				buy_btn.add_theme_stylebox_override("normal", s)
	
	
	
	
	
	
