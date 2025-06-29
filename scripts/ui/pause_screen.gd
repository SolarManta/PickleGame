extends Control
class_name PauseScreen

func _process(_delta: float):
	pass
	
func _input(_event: InputEvent):
	if Input.is_action_just_pressed("Pause"):
		if visible:
			AudioManager.play_audio(self, "unpaused", "SFX")
		else:
			AudioManager.play_audio(self, "paused", "SFX")
		visible = !visible
		get_tree().paused = visible
		
func _play_hover():
	AudioManager.play_audio(self, "hover_button", "SFX")

func _on_settings_pressed():
	add_child(preload("res://scenes/ui/settings.tscn").instantiate())

func _on_resume_pressed():
	visible = false
	AudioManager.play_audio(self, "unpaused", "SFX")
	get_tree().paused = false

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("scenes//ui/start_screen.tscn")
