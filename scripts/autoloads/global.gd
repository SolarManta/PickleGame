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
	var controlLoad: SaveConfig = ResourceLoader.load("user://saves/controls.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SaveConfig
	if controlLoad:
		var controlConfigDic: Dictionary = controlLoad.data_dic
		for key in controlConfigDic.keys():
			InputMap.action_erase_events(key)
			InputMap.action_add_event(key, controlConfigDic[key])

func load_volume():
	var volumeLoad : SaveConfig = ResourceLoader.load("user://saves/settings.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SaveConfig
	if volumeLoad:
		var volumeConfigDic: Dictionary = volumeLoad.data_dic
		for key in volumeConfigDic.keys():
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(key), linear_to_db(volumeConfigDic[key]))

func create_volume():
	var config: SaveConfig = SaveConfig.new()
	config.data_dic = { 
		"Master" = 1,
		"SFX" = 1,
		"Music" = 1
	}
	ResourceSaver.save(config, "user://saves/settings.tres", ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
