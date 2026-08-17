extends MarginContainer

@export_group("Sounds")
@export var trumpet_sfx: Array[AudioStream]
@export var falling_sfx: Array[AudioStream]
@export var crash_sfx: Array[AudioStream]

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer

@onready var title_logo_complete: Texture2D = load("uid://b5w0pc7x5csx5")
@onready var title_logo: TextureRect = $VBoxContainer/Logo
@onready var title_joke_logo: Label = $VBoxContainer/JokeLogo
@onready var title_info_box: TextureRect = $VBoxContainer/Info
@onready var whiteout: ColorRect = $"../Whiteout"
@onready var title_background: Control = $"../ScrollingBackground"

func _ready() -> void:
	title_begin_title_reveal()

func play_audio(streams: Array[AudioStream]):
	var choice: int = randi_range(0, len(streams) - 1)
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

func title_begin_title_reveal():
	var tween := create_tween()
	tween.tween_callback(play_audio.bind(trumpet_sfx))
	tween.tween_interval(4 - trumpet_sfx[0].get_length())
	tween.tween_callback(func():
		play_audio(falling_sfx)
	)
	tween.tween_interval(2)
	tween.tween_callback(func(): title_logo.modulate.a = 1)
	tween.parallel().tween_property(title_logo, "offset_transform_scale", Vector2(1, 1), .5)
	tween.parallel().tween_method(screen_shake, 10, 5, 0.35).set_delay(.4)
	tween.parallel().tween_callback(play_audio.bind(crash_sfx)).set_delay(.4)
	tween.tween_callback(func():
		title_logo.modulate.a = 0
		position = Vector2.ZERO
	)
	tween.tween_callback(func(): title_logo.modulate.a = 1).set_delay(.05)
	tween.tween_callback(whiteout.show)
	tween.parallel().tween_property(whiteout, "modulate:a", 1, 0.2)
	tween.tween_callback(func():
		title_logo.texture = title_logo_complete
		title_joke_logo.hide()
		title_background.show()
		music_player.play()
		title_info_box.show()
		var tween_drop_infobox := create_tween()
		tween_drop_infobox.tween_callback(title_info_box.show).set_delay(19)
		tween_drop_infobox.tween_property(title_info_box, "offset_transform_position:y", -10, 1)
		tween_drop_infobox.tween_property(title_info_box, "offset_transform_position:y", -50, .1)
		tween_drop_infobox.tween_interval(.05)
		tween_drop_infobox.tween_property(title_info_box, "offset_transform_position:y", -10, .1)
		tween_drop_infobox.set_trans(Tween.TRANS_CUBIC)
	)
	tween.tween_property(whiteout, "modulate:a", 0, 0.2)
	tween.set_trans(Tween.TRANS_CUBIC)

func screen_shake(intensity: float):
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity
