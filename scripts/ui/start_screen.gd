extends Control
class_name StartScreen

func _ready():
	pass

func _on_start_pressed():
	get_tree().change_scene_to_file("scenes//level.tscn")

func _play_hover():
	AudioManager.play_audio(self, "hover_button", "SFX")

func _on_settings_pressed():
	add_child(preload("res://scenes/ui/settings.tscn").instantiate())

func _on_quit_pressed():
	get_tree().quit()
