extends Node

func _ready() -> void:
	UserSettingsInstance.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(id: StringName, new_value: Variant) -> void:
	if id == &"fullscreen":
		var new_mode := DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
		if new_value:
			new_mode = DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(new_mode)