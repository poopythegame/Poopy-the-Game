extends Resource
class_name RankDef

@export var letter: String
@export var icon: Texture2D
@export var small_icon: Texture2D
@export var animation_frames: Array[Texture2D]
@export_custom(PROPERTY_HINT_NONE, "suffix:fps") var animation_fps: float
@export_range(.001, 60 * 60, .001, "suffix:s") var time: float