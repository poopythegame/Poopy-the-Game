extends Node2D

@export var heal_amount := 5.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var animation_duration := 1.5
@export_group("Sounds")
@export var collect_sfx: Array[AudioStream]

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var used: bool = false

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
	var area_2d = $Area2D
	area_2d.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Player and not used:
		# a player picked up the coin
		animated_sprite_2d.play("spin")
		play_audio(collect_sfx)
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0, animation_duration)
		tween.parallel().tween_property(self, "position:y", position.y - 50, animation_duration)
		tween.tween_callback(hide)
		used = true
		if body.health < body.max_health:
			body.health += 5
		# This automatically adds the coin to the correct level "bucket"
		Global.add_coin()
