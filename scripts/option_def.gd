extends Resource
class_name OptionDef

@export var title: String
@export var portrait: Texture2D
@export_group("Label Icon")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var use_label_icon := false
## An icon to use instead of a label.
@export var label_icon: Texture2D