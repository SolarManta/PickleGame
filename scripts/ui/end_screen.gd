extends Control
class_name EndScreen


func _on_retry_pressed():
	get_tree().change_scene_to_file("scenes//level.tscn")

func _on_quit_pressed():
	get_tree().change_scene_to_file("scenes//start_screen.tscn")

func _play_hover():
	AudioManager.play_audio(self, "hover_button", "SFX")
