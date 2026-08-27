extends Sprite2D

@export var video: VideoStream

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	video_stream_player.stream = video

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("up"):
		video_stream_player.show()
		video_stream_player.play()