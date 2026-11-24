extends Control

class InputActionControls:
	var label: Label
	var mnk_record_btn: Button
	var controller_record_btn: Button
	func _init(label: Label, mnk_record_btn: Button, controller_record_btn) -> void:
		self.label = label
		self.mnk_record_btn = mnk_record_btn
		self.controller_record_btn = controller_record_btn

@onready var controls_container: GridContainer = %ActionsContainer

var input_action_controls: Dictionary[StringName, InputActionControls]

func _ready() -> void:
	if not InputMapper.is_node_ready():
		InputMapper.ready.connect(_create_input_action_controls)
	else:
		_create_input_action_controls()

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
		input_action_controls[input_action.id] = InputActionControls.new(label, mnk_record_btn, controller_record_btn)
		controls_container.add_child(label)
		controls_container.add_child(mnk_record_btn)
		controls_container.add_child(controller_record_btn)
