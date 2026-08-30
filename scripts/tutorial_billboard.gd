extends Sprite2D

@export var video: VideoStream

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var area_2d: Area2D = $Area2D
var player: Player

func _ready() -> void:
	video_stream_player.stream = video
	player = get_tree().get_first_node_in_group("Player")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("up") and player in area_2d.get_overlapping_bodies():
		video_stream_player.show()
		video_stream_player.play()