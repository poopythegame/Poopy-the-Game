extends Resource
class_name OptionDef

@export var title: String
@export var portrait: Texture2D
@export_group("Animated Overlay")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_animated_overlay := false
@export var animated_overlay_frames: Array[Texture2D] = []
@export_range(1, 60, 1, "suffix:fps") var animated_overlay_fps := 12.
@export_group("Label Icon")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var use_label_icon := false
## An icon to use instead of a label.
@export var label_icon: Texture2D