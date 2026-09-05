extends Sprite2D

## Use an MP4 or WebM video file, but provide an identically named OGV fallback (for Web) in the same folder.
@export_file_path var video_path: String
@export var use_fallback: bool = false

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var area_2d: Area2D = $Area2D
var player: Player
var video: VideoStream
var can_play: bool = true

func _ready() -> void:
	if OS.has_feature("web") or use_fallback:
		var base_name: String = video_path.get_basename()
		var fallback_path: String = base_name + ".ogv"
		if not FileAccess.file_exists(fallback_path):
			push_error("Web: couldn't load fallback video at " + fallback_path + ". Video will not play.")
			can_play = false
		video = load(fallback_path)
	else:
		video = load(video_path)
	video_stream_player.stream = video
	player = get_tree().get_first_node_in_group("Player")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("up") and player in area_2d.get_overlapping_bodies() and can_play:
		video_stream_player.show()
		video_stream_player.play()