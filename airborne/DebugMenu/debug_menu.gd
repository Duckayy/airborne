# debug_menu.gd
# Attach to a CanvasLayer node. Drop into any scene.
# Add panels by calling register_panel(title, content_builder_func)
extends CanvasLayer
class_name DebugMenu

var menu_visible = false
var panels: Array = []
var vbox: VBoxContainer = null

func _ready():
	layer = 20
	_build_ui()
	visible = false

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			menu_visible = !menu_visible
			visible = menu_visible
			if menu_visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_ui():
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# Scroll container
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20
	scroll.offset_top = 20
	scroll.offset_right = -20
	scroll.offset_bottom = -20
	root.add_child(scroll)

	vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 520
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	# Header
	var title = Label.new()
	title.text = "DEBUG MENU"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Press F1 to toggle"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	_add_separator()

# Called by panels to register themselves
func register_panel(title: String, builder: Callable):
	var section = _build_collapsible_section(title, builder)
	vbox.add_child(section)
	_add_separator()

func _build_collapsible_section(title: String, builder: Callable) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var header = Button.new()
	header.text = "▼  " + title
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_font_size_override("font_size", 16)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	header_style.corner_radius_top_left = 6
	header_style.corner_radius_top_right = 6
	header.add_theme_stylebox_override("normal", header_style)
	header.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	header.custom_minimum_size.y = 36
	container.add_child(header)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	container.add_child(content)

	builder.call(content)

	# Use a RefCounted wrapper to avoid lambda capture warning
	var state = {"open": true}
	header.pressed.connect(func():
		state["open"] = !state["open"]
		content.visible = state["open"]
		header.text = ("▼  " if state["open"] else "▶  ") + title
	)

	return container

func _add_separator():
	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 6
	vbox.add_child(sep)

# --- UI Helpers (used by panels) ---
static func make_button(parent: Control, text: String, color: Color = Color(0.1, 0.4, 0.25)) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 38)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.9, 0.5, 0.3)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(btn)
	return btn

static func make_label(parent: Control, text: String, size: int = 14) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	parent.add_child(lbl)
	return lbl

static func make_slider(parent: Control, label_text: String, min_val: float, max_val: float, current: float, on_change: Callable) -> HSlider:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 180
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	row.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = current
	slider.custom_minimum_size.x = 150
	row.add_child(slider)
	var val_label = Label.new()
	val_label.text = str(snappedf(current, 0.01))
	val_label.custom_minimum_size.x = 60
	val_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	row.add_child(val_label)
	slider.value_changed.connect(func(val):
		val_label.text = str(snappedf(val, 0.01))
		on_change.call(val)
	)
	return slider
