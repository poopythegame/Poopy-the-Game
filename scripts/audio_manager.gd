extends Node

var master_bus: int
var music_bus: int
var sfx_bus: int

func _ready() -> void:
	UserSettingsInstance.setting_changed.connect(_on_setting_changed)
	master_bus = AudioServer.get_bus_index("Master")
	music_bus = AudioServer.get_bus_index("Music")
	sfx_bus = AudioServer.get_bus_index("SFX")

func _on_setting_changed(id: StringName, value: Variant) -> void:
	if id == &"master_volume":
		AudioServer.set_bus_volume_linear(master_bus, value)
	elif id == &"music_volume":
		AudioServer.set_bus_volume_linear(music_bus, value)
	elif id == &"sound_volume":
		AudioServer.set_bus_volume_linear(sfx_bus, value)