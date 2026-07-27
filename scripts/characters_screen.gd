@tool
extends MultiselectScreen

func _preview_option(option: OptionDef) -> Control:
	var texture: TextureRect = super._preview_option(option)
	texture.size_flags_horizontal = SIZE_EXPAND_FILL
	var container: HBoxContainer = HBoxContainer.new()
	container.add_child(texture)
	var bio_label: Label = Label.new()
	bio_label.text = option.bio
	bio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bio_label.add_theme_font_size_override("font_size", 28)
	bio_label.size_flags_horizontal = SIZE_EXPAND_FILL
	bio_label.custom_maximum_size = Vector2(394, -1)
	bio_label.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD
	container.add_child(bio_label)
	return container