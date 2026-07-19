extends Resource
class_name RankDef

@export var letter: String
@export var icon: Texture2D
@export var small_icon: Texture2D
@export var animation_frames: Array[Texture2D]
@export_custom(PROPERTY_HINT_NONE, "suffix:fps") var animation_fps: float
@export_range(.001, 60 * 60, .001, "suffix:s") var time: float
@export_group("Music")
@export var music_track_1: AudioStream
@export var music_track_2: AudioStream
@export_group("Special Effects")
@export var is_animation_one_shot := false
@export var use_walk_off_animation := false
@export_enum("Off", "Normal", "Fast") var show_portraits_background = 0
@export var flip_animation := false