extends Node

# Creates and attaches an AudioStreamPlayer to the SceneTree. Deletes the AudioStreamPlayer when finished
func play_audio(parent: Node, aname: String, abus: String, positional: bool = false):
	var temp
	if positional:
		temp = AudioStreamPlayer2D.new()
	else:
		temp = AudioStreamPlayer.new()
	temp.name = aname
	temp.stream = load("res://assets/" + abus.to_lower() + "/" + aname + ".wav")
	temp.bus = abus
	parent.add_child(temp)
	temp.finished.connect(temp.queue_free)
	temp.play()
