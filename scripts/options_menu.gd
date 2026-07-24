extends CenterContainer
class_name OptionsMenu

@onready var options_container: GridContainer = $OptionsContainer

func _create_controls() -> void:
	for result in UserSettingsInstance.list_settings():
		var label: Label = Label.new()
		label.text = result.name
		options_container.add_child(label)
		var control: Control
		if result.type == TYPE_BOOL:
			control = CheckButton.new()
			control.button_pressed = result.value
			control.pressed.connect(func():
				UserSettingsInstance.set(result.id, control.button_pressed)
			)
			control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		elif result.type == TYPE_FLOAT:
			control = HSlider.new()
			control.min_value = 0
			control.max_value = 1
			control.step = .01
			control.value = result.value
			control.changed.connect(func():
				UserSettingsInstance.set(result.id, control.value)
			)
		control.custom_minimum_size = Vector2(250, 0)
		control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		options_container.add_child(control)

func _on_enter() -> void:
	options_container.get_child(1).grab_focus()

func _ready() -> void:
	_create_controls()