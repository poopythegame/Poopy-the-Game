extends Area2D

@export var go_texture: Texture2D
@export var hold_texture: Texture2D
@export_group("Sounds")
@export var beep_sfx: Array[AudioStream]

@onready var main: InGameOverlay = get_parent().get_node("InGameOverlay")
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var indicator_sprite: Sprite2D = $Indicator

func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
	audio_stream_player.stream = streams[choice]
	audio_stream_player.play()

func _ready() -> void:
	indicator_sprite.texture = hold_texture

func _on_area_entered(collision_area: Area2D) -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player and collision_area == player.get_collision_area():
		if main.stopwatch_paused:
			play_audio(beep_sfx)
			indicator_sprite.texture = go_texture
		main.stopwatch_paused = false
