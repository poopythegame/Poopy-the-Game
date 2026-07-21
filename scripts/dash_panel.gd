extends Node

@export var strength: float = 500
@export var flip: bool = false
@export_group("Sounds")
@export var use_sfx: Array[AudioStream]

@onready var area: Area2D = $Area2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
	# var not_playing_current_sfx := true
	# for stream in streams:
	# 	if stream == audio_stream_player.stream:
	# 		not_playing_current_sfx = false
	# if not_playing_current_sfx:
	audio_stream_player.stream = streams[choice]
	audio_stream_player.play()

func stop_audio():
	var stream := audio_stream_player.stream
	if stream is AudioStreamWAV:
		if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			audio_stream_player.stop()
	elif stream is AudioStreamOggVorbis:
		if stream.loop:
			audio_stream_player.stop()
	elif stream is AudioStreamMP3:
		if stream.loop:
			audio_stream_player.stop()
	if not audio_stream_player.playing:
		audio_stream_player.stream = null

func _ready() -> void:
	area.body_entered.connect(_contact)
	if flip:
		var sprite: Sprite2D = $Sprite2D
		sprite.flip_h = true

func _contact(body):
	if body is Player:
		var player: Player = body
		var motion: Vector2 = Vector2(1, 0)
		if flip:
			motion.x = -1
		motion *= strength
		player.motion = motion
		play_audio(use_sfx)
