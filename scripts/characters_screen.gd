@tool
extends MultiselectScreen

func _preview_option(option: OptionDef, option_index: int) -> Control:
	var texture: TextureRect = super._preview_option(option, option_index)
	texture.size_flags_horizontal = SIZE_EXPAND_FILL
	var container: HBoxContainer = HBoxContainer.new()
	container.add_child(texture)
	var bio_label: Label = Label.new()
	bio_label.text = option.bio
	bio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bio_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	bio_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bio_label.size_flags_horizontal = SIZE_EXPAND_FILL
	bio_label.custom_maximum_size = Vector2(394, -1)
	bio_label.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD
	bio_label.add_theme_constant_override("line_spacing", 8)
	bio_label.add_theme_font_size_override("font_size", 24)
	bio_label.offset_transform_enabled = true
	bio_label.offset_transform_position = Vector2(5, 110)
	container.add_child(bio_label)
	return container
