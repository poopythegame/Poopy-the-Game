extends Node

const INPUT_MAP_PATH := "bindings.json"

const JOY_BUTTON_NAMES: Dictionary = {
	JOY_BUTTON_INVALID: "Invalid",
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "Left Stick",
	JOY_BUTTON_RIGHT_STICK: "Right Stick",
	JOY_BUTTON_LEFT_SHOULDER: "Left Shoulder",
	JOY_BUTTON_RIGHT_SHOULDER: "Right Shoulder",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
	JOY_BUTTON_MISC1: "Misc",
	JOY_BUTTON_PADDLE1: "Paddle 1",
	JOY_BUTTON_PADDLE2: "Paddle 2",
	JOY_BUTTON_PADDLE3: "Paddle 3",
	JOY_BUTTON_PADDLE4: "Paddle 4",
	JOY_BUTTON_TOUCHPAD: "Touchpad",
}

const JOY_AXIS_NAMES: Dictionary = {
	JOY_AXIS_INVALID: "Invalid",
	JOY_AXIS_LEFT_X: "Left Stick",
	JOY_AXIS_LEFT_Y: "Left Stick",
	JOY_AXIS_RIGHT_X: "Right Stick",
	JOY_AXIS_RIGHT_Y: "Right Stick",
	JOY_AXIS_TRIGGER_LEFT: "Left Trigger",
	JOY_AXIS_TRIGGER_RIGHT: "Right Trigger",
}

const DIRECTIONAL_JOY_AXES: Array[int] = [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]

const MOUSE_BUTTON_NAMES: Dictionary = {
	MOUSE_BUTTON_NONE: "None",
	MOUSE_BUTTON_LEFT: "Left Mouse Button",
	MOUSE_BUTTON_RIGHT: "Right Mouse Button",
	MOUSE_BUTTON_MIDDLE: "Middle Mouse Button",
	MOUSE_BUTTON_WHEEL_UP: "Mouse Wheel Up",
	MOUSE_BUTTON_WHEEL_DOWN: "Mouse Wheel Down",
	MOUSE_BUTTON_WHEEL_LEFT: "Mouse Wheel Left",
	MOUSE_BUTTON_WHEEL_RIGHT: "Mouse Wheel Right",
	MOUSE_BUTTON_XBUTTON1: "Mouse Button 4",
	MOUSE_BUTTON_XBUTTON2: "Mouse Button 5",
}

static func get_joy_stick_directional_suffix(axis: int, positive: bool) -> String:
	if positive:
		if axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_RIGHT_X:
			return "Right"
		elif axis == JOY_AXIS_LEFT_Y or axis == JOY_AXIS_RIGHT_Y:
			return "Down"
		else:
			return "Unknown"
	else:
		if axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_RIGHT_X:
			return "Left"
		elif axis == JOY_AXIS_LEFT_Y or axis == JOY_AXIS_RIGHT_Y:
			return "Up"
		else:
			return "Unknown"

class ActionInfo:
	var id: StringName
	var display_name: String
	var mnk_event: InputEvent
	var controller_event: InputEvent
	var modified: bool
	func _init(id: StringName, display_name: String) -> void:
		self.id = id
		self.display_name = display_name
		var events := InputMap.action_get_events(id)
		for event in events:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				if controller_event == null:
					controller_event = event
			elif event is InputEventKey or event is InputEventMouseButton:
				if mnk_event == null:
					mnk_event = event
		
static func get_all_action_info() -> Dictionary[StringName, ActionInfo]:
	var dictionary: Dictionary[StringName, ActionInfo] = {}
	for action in InputMap.get_actions():
		if not action.begins_with("ui_"):
			dictionary[action] = action_info_from_id(action)
	return dictionary

static func action_info_from_id(id: StringName) -> ActionInfo:
	var display_name := id.capitalize()
	return ActionInfo.new(id, display_name)
	
# Used for serializing InputEvent's
static func serialize_resource(res: Resource) -> String:
	var data := {}
	data["__type"] = res.get_class()
	for prop in res.get_property_list():
		if prop.usage & PROPERTY_USAGE_STORAGE and prop.name != "script":
			data[prop.name] = res.get(prop.name)
	
	return var_to_str(data)

static func deserialize_resource(text: String) -> Resource:
	var data: Dictionary = str_to_var(text)
	var target = ClassDB.instantiate(data["__type"])
	for key in data:
		target.set(key, data[key])
	return target 

signal input_action_updated(id: StringName)

var action_info: Dictionary[StringName, ActionInfo]
var recording := false
var record_target: StringName
var record_to_controller: bool

func apply_event_to_action(action_name: StringName, event: InputEvent, is_controller: bool = false, silent: bool = false) -> void:
	var action_info: ActionInfo = action_info[action_name]
	if is_controller:
		if event is not InputEventJoypadButton and event is not InputEventJoypadMotion:
			push_error("Cannot apply event that isn't controller to controller channel.")
			return
		InputMap.action_erase_event(action_info.id, action_info.controller_event)
		action_info.controller_event = event
		InputMap.action_add_event(action_info.id, event)
		if not silent:
			action_info.modified = true
			input_action_updated.emit(action_info.id)
	else:
		if event is not InputEventKey and event is not InputEventMouseButton:
			push_error("Cannot apply event that isn't MnK to MnK channel.")
			return
		InputMap.action_erase_event(action_info.id, action_info.mnk_event)
		action_info.mnk_event = event
		InputMap.action_add_event(action_info.id, event)
		if not silent:
			action_info.modified = true
			input_action_updated.emit(action_info.id)

func activate_recording_for(action_name: StringName, target_controller: bool) -> void:
	recording = true
	record_target = action_name
	record_to_controller = target_controller

func cancel_recording() -> void:
	recording = false

func stringify_event(event: InputEvent):
	if event is InputEventJoypadButton:
		return JOY_BUTTON_NAMES[event.button_index]
	elif event is InputEventKey:
		return event.as_text().trim_suffix(" - Physical")
	elif event is InputEventMouseButton:
		return MOUSE_BUTTON_NAMES[event.button_index]
	elif event is InputEventJoypadMotion:
		var index: JoyAxis = event.axis 
		if index in DIRECTIONAL_JOY_AXES:
			var suffix := get_joy_stick_directional_suffix(index, event.axis_value > 0)
			return "%s %s" % [JOY_AXIS_NAMES[index], suffix]
		else:
			return JOY_AXIS_NAMES[index]

func save_input_map() -> void:
	var data_dir := OS.get_user_data_dir()
	var input_map_path := data_dir.path_join(INPUT_MAP_PATH)
	var input_map: Dictionary = {}
	for input_action: ActionInfo in action_info.values():
		if input_action.modified:
			input_map[String(input_action.id)] = {
				"mnk_binding": serialize_resource(input_action.mnk_event),
				"controller_binding": serialize_resource(input_action.controller_event)
			}
	var input_map_json: String = JSON.stringify(input_map)
	var file := FileAccess.open(input_map_path, FileAccess.ModeFlags.WRITE)
	file.store_string(input_map_json)
	file.close()

func load_input_map() -> void:
	var data_dir := OS.get_user_data_dir()
	var input_map_path := data_dir.path_join(INPUT_MAP_PATH)
	if FileAccess.file_exists(input_map_path):
		var contents := FileAccess.open(input_map_path, FileAccess.ModeFlags.READ).get_as_text()
		var json := JSON.new()
		var error := json.parse(contents)
		if error == OK and typeof(json.data) == TYPE_DICTIONARY:
			deserialize_input_map(json.data)

func deserialize_input_map(map: Dictionary):
	for key: String in map.keys():
		var data: Dictionary = map[key]
		if key in action_info:
			var mnk_action: InputEvent = deserialize_resource(data["mnk_binding"])
			apply_event_to_action(key, mnk_action, false, true)
			var controller_action: InputEvent = deserialize_resource(data["controller_binding"])
			apply_event_to_action(key, controller_action, true, true)

func _ready() -> void:
	action_info = get_all_action_info()
	load_input_map()

func _exit_tree() -> void:
	save_input_map()

func _input(event: InputEvent) -> void:
	if recording:
		if record_to_controller:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				apply_event_to_action(record_target, event, true)
				recording = false
		else:
			if event is InputEventKey or event is InputEventMouseButton:
				apply_event_to_action(record_target, event, false)
				recording = false
		get_viewport().set_input_as_handled()
