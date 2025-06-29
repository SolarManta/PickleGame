extends Control
class_name Settings

var _fullscreen_button: TextureButton
var _sliders: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	_fullscreen_button = get_node("Fullscreen") as TextureButton
	_sliders = get_tree().get_nodes_in_group("VolumeSliders")

	_fullscreen_button.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	load_volume()

func _play_hover():
	AudioManager.play_audio(self, "hover_button", "SFX")

func _on_back_pressed():
	queue_free()

func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_controls_pressed():
	add_child(preload("res://scenes/ui/controls.tscn").instantiate())

func load_volume():
	DirAccess.make_dir_absolute("user://saves")
	var save_data: SaveConfig = ResourceLoader.load("user://saves/settings.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SaveConfig

	for slider: HSlider in _sliders:
		slider.value = save_data.data_dic[slider.name]
