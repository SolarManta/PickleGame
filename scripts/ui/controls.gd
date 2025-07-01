extends Control
class_name Controls

var _current_button: Button
var _current_action: String
var _remapping: bool
var _scroll_box: ScrollContainer

func _ready():
	_scroll_box = get_node("ScrollContainer")
	for button: Button in get_tree().get_nodes_in_group("RemapButtons"):
		button.connect("pressed", _on_button_pressed.bind(button))
		button.connect("mouse_entered", _play_hover)
		
	if !ResourceLoader.exists("user://saves/controls.tres"):
		return
	
	_save_controls()

func _update_button_text():
	var save_data: SaveConfig = ResourceLoader.load("user://saves/controls.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SaveConfig
	for button: Button in get_tree().get_nodes_in_group("RemapButtons"):
		button.text = _return_text(save_data.data_dic[button.name])

func _play_hover():
	AudioManager.play_audio(self, "hover_button", "SFX")

func _on_back_pressed():
	if !_remapping:
		queue_free()

func _on_reset_pressed():
	if !_remapping:
		InputMap.load_from_project_settings()
		_save_controls()

func _on_button_pressed(button: Button):
	if !_remapping:
		_remapping = true
		_current_button = button
		_current_action = button.name
		button.text = "-"
		_scroll_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		_scroll_box.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

func _return_text(event: InputEvent) -> String:
	var text = ""
	if event is InputEventKey:
		var keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		text = OS.get_keycode_string(keycode)
	elif event is InputEventMouseButton:
		event = (event as InputEventMouseButton)
		var as_string = event.as_text()
		match as_string:
			"Left Mouse Button":
				text = "M1"
			"Right Mouse Button":
				text = "M2"
			"Middle Mouse Button":
				text = "M3"
			"Mouse Wheel Up":
				text = "MW Up"
			"Mouse Wheel Down":
				text = "MW Down"
	return text

func _input(event: InputEvent):
	var temp: InputEvent = event
	if _remapping and _return_text(event) != "":
		InputMap.action_erase_events(_current_action)
		InputMap.action_add_event(_current_action, temp)
		_remapping = false
		_scroll_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_scroll_box.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_save_controls()

func _save_controls():
	var input_config = SaveConfig.new()
	input_config.data_dic = {}

	for button: Button in get_tree().get_nodes_in_group("RemapButtons"):
		if !InputMap.action_get_events(button.name):
			_on_reset_pressed()
			break
		input_config.data_dic[button.name] = InputMap.action_get_events(button.name)[0]

	ResourceSaver.save(input_config, "user://saves/controls.tres", ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	_update_button_text()
