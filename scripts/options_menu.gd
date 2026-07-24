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
			control.toggled.connect(func(checked):
				UserSettingsInstance.set(result.id, checked)
			)
			control.size_flags_horizontal = Control.SIZE_SHRINK_END
		elif result.type == TYPE_FLOAT:
			control = HSlider.new()
			control.min_value = 0
			control.max_value = 1
			control.step = .01
			control.value = result.value
			control.value_changed.connect(func(new_value: float):
				UserSettingsInstance.set(result.id, new_value)
			)
			control.custom_minimum_size = Vector2(250, 0)
		control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		options_container.add_child(control)

func _on_enter() -> void:
	options_container.get_child(1).grab_focus()

func _ready() -> void:
	_create_controls()