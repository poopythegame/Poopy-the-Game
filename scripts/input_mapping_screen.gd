extends Control

class InputActionControls:
	var id: StringName
	var label: Label
	var mnk_record_btn: Button
	var controller_record_btn: Button
	func _init(id: StringName, label: Label, mnk_record_btn: Button, controller_record_btn) -> void:
		self.id = id
		self.label = label
		self.mnk_record_btn = mnk_record_btn
		self.controller_record_btn = controller_record_btn
		self.mnk_record_btn.pressed.connect(on_mnk_record_start)
		self.controller_record_btn.pressed.connect(on_controller_record_start)
	func on_mnk_record_start() -> void:
		InputMapper.activate_recording_for(id, false)
	func on_controller_record_start() -> void:
		InputMapper.activate_recording_for(id, true)
	
@onready var controls_container: GridContainer = %ActionsContainer

var input_action_controls: Dictionary[StringName, InputActionControls]

func _ready() -> void:
	if not InputMapper.is_node_ready():
		InputMapper.ready.connect(_create_input_action_controls)
	else:
		_create_input_action_controls()
	InputMapper.input_action_updated.connect(_on_input_action_updated)

func _on_enter() -> void:
	# 0, 1, and 2 are the header labels. 3 is the action's name, so the first button will be 4, the first action's recording button for MnK.
	var candidate := controls_container.get_child(4)
	if candidate != null and candidate is Control:
		candidate.grab_focus()

func _on_input_action_updated(id: StringName) -> void:
	var controls := input_action_controls[id]
	var action_info := InputMapper.action_info[id]
	if action_info.mnk_event == null:
		controls.mnk_record_btn.text = "Unbound"
	else:
		controls.mnk_record_btn.text = InputMapper.stringify_event(action_info.mnk_event)
	if action_info.controller_event == null:
		controls.controller_record_btn.text = "Unbound"
	else:
		controls.controller_record_btn.text = InputMapper.stringify_event(action_info.controller_event)

func _create_input_action_controls() -> void:
	for input_action in InputMapper.action_info.values():
		var label := Label.new()
		label.text = input_action.display_name
		var mnk_record_btn := Button.new()
		if input_action.mnk_event == null:
			mnk_record_btn.text = "Unbound"
		else:
			mnk_record_btn.text = InputMapper.stringify_event(input_action.mnk_event)
		var controller_record_btn := Button.new()
		if input_action.controller_event == null:
			controller_record_btn.text = "Unbound"
		else:
			controller_record_btn.text = InputMapper.stringify_event(input_action.controller_event)
		input_action_controls[input_action.id] = InputActionControls.new(input_action.id, label, mnk_record_btn, controller_record_btn)
		controls_container.add_child(label)
		controls_container.add_child(mnk_record_btn)
		controls_container.add_child(controller_record_btn)
