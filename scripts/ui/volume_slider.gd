extends HSlider

var _bus_index: int
@export var _bus_name: String

func _ready():
	_bus_index = AudioServer.get_bus_index(_bus_name)
	value = db_to_linear(AudioServer.get_bus_volume_db(_bus_index))

func _on_value_changed(newValue: float):
	AudioServer.set_bus_volume_db(_bus_index, linear_to_db(newValue))
	save_volume()

func save_volume():
	var save_data: SaveConfig = ResourceLoader.load("user://saves/settings.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SaveConfig

	save_data.data_dic[name] = value

	ResourceSaver.save(save_data, "user://saves/settings.tres", ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
