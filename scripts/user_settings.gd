extends Node
class_name UserSettings

signal setting_changed(id: StringName, value: Variant)

var settings: Dictionary[StringName, Variant]

class Setting:
	var name: String
	var id: String
	var type: Variant.Type
	var value: Variant

func _get_default_settings() -> Dictionary[StringName, Variant]:
	return {
		&"enable_camera_lookahead": true,
		&"master_volume": 1.,
		&"music_volume": 1.,
		&"sound_volume": 1.,
	}

func _enter_tree() -> void:
	var data_dir := OS.get_user_data_dir()
	var settings_path := data_dir.path_join("settings.json")
	var should_use_defaults := false
	if not FileAccess.file_exists(settings_path):
		should_use_defaults = true
	else:
		var contents := FileAccess.open(settings_path, FileAccess.READ)
		var json := JSON.new()
		var error = json.parse(contents.get_as_text())
		if error == OK and typeof(json.data) == TYPE_DICTIONARY:
			settings.assign(json.data)
		else:
			should_use_defaults = true

	if should_use_defaults:
		settings = _get_default_settings()
	
	# Trigger an update for all setting values after all nodes are ready
	_update_all_settings.call_deferred()

func _update_all_settings() -> void:
	for setting_id in settings.keys():
		var value: Variant = settings[setting_id]
		setting_changed.emit(setting_id, value)

func list_settings() -> Array[Setting]:
	var results: Array[Setting] = []
	for key: String in settings.keys():
		var value = settings.get(key)
		var desc = Setting.new()
		desc.name = key.capitalize()
		desc.id = key
		desc.type = typeof(value)
		desc.value = value
		results.append(desc)
	return results

func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for key in settings.keys():
		var value = settings.get(key)
		list.append({
			"name": key,
			"type": typeof(value),
			"value": value
		})
	return list

func _get(property: StringName) -> Variant:
	var key: String = String(property)
	if settings.has(key):
		return settings[key]
	return null

func _set(property: StringName, value: Variant) -> bool:
	var key: String = String(property)
	settings[key] = value
	setting_changed.emit(key, value)
	save_settings()
	return true

func save_settings() -> void:
	var data_dir := OS.get_user_data_dir()
	var settings_path := data_dir.path_join("settings.json")
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(settings, "  "))
	file.close()

func _exit_tree() -> void:
	save_settings()
