extends Node

func _ready():
	DirAccess.make_dir_absolute("user://saves")
	if ResourceLoader.exists("user://saves/controls.tres", ""):
		load_controls()
	if ResourceLoader.exists("user://saves/settings.tres"):
		load_volume()
	else:
		create_volume()

func load_controls():
	var control_load: SaveConfig = ResourceLoader.load("user://saves/controls.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SaveConfig
	if control_load:
		var control_config_dic: Dictionary = control_load.data_dic
		for key in control_config_dic.keys():
			InputMap.action_erase_events(key)
			InputMap.action_add_event(key, control_config_dic[key])

func load_volume():
	var volume_load : SaveConfig = ResourceLoader.load("user://saves/settings.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SaveConfig
	if volume_load:
		var volume_config_dic: Dictionary = volume_load.data_dic
		for key in volume_config_dic.keys():
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(key), linear_to_db(volume_config_dic[key]))

func create_volume():
	var config: SaveConfig = SaveConfig.new()
	config.data_dic = { 
		"Master" = 1,
		"SFX" = 1,
		"Music" = 1
	}
	ResourceSaver.save(config, "user://saves/settings.tres", ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
