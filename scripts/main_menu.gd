extends Control
class_name MainMenu

@export var labels_slide_time := 2.
@export var start_screen := Screen.TITLE
@export_group("Sounds")
@export var left_sfx: Array[AudioStream]
@export var select_sfx: Array[AudioStream]
@export var right_sfx: Array[AudioStream]

enum Screen {
	TITLE,
	MENU,
	CREDITS,
	LEVEL_SELECT,
	OPTIONS,
	CHARACTERS,
}

@onready var label_settings: LabelSettings = load("uid://o04nc50d6jgm")
@onready var title_logo_complete: Texture2D = load("uid://b5w0pc7x5csx5")
@onready var title_audio_stream: AudioStreamOggVorbis = load("uid://cotx67p5iwda")
@onready var menu_audio_stream: AudioStreamOggVorbis = load("uid://b26trx8dyw833")

@onready var music_player: AudioStreamPlayer = $MusicPlayer


@onready var title_screen: MarginContainer = $TitleScreen
@onready var title_logo: TextureRect = $TitleScreen/VBoxContainer/Logo
@onready var title_joke_logo: Label = $TitleScreen/VBoxContainer/JokeLogo
@onready var title_info_box: PanelContainer = $TitleScreen/VBoxContainer/Info
@onready var background: TextureRect = $Background
@onready var whiteout: ColorRect = $Whiteout
@onready var title_poopy: AnimatedSprite2D = $TitleScreen/VBoxContainer/Logo/PoopyContainer/Poopy
@onready var title_portraits_background: Node2D = $TitleScreen/PortraitsBackground
@onready var title_infobox: PanelContainer = $TitleScreen/VBoxContainer/Info

@onready var menu_screen: MultiselectScreen = $Menu

@onready var level_select_screen: LevelSelect = $LevelSelect

@onready var levels := Global.levels.levels

var screen := Screen.TITLE
var main_scene: PackedScene
var screen_rect: Rect2

var title_title_reveal_tween: Tween
var title_poopy_jump_vel: float
var title_poopy_last_frametime := 0.

var level_select_selected := 0
var level_select_slide_tween: Tween
var level_select_labels: Array[Label] = []

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
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
	if Engine.is_editor_hint():
		screen_rect = Rect2(0, 0, ProjectSettings.get("display/window/size/viewport_width"), ProjectSettings.get("display/window/size/viewport_height"))
	else:
		screen_rect = get_viewport_rect()
		menu_screen.option_selected.connect(_on_menu_option_selected)
	title_portraits_background.process_mode = Node.PROCESS_MODE_DISABLED
	change_screen(start_screen)

func _on_menu_option_selected(index: int):
	if index == 0:
		pass
	elif index == 1:
		change_screen(Screen.LEVEL_SELECT)
	elif index == 2:
		pass
	elif index == 3:
		change_screen(Screen.CHARACTERS)

func _input(event: InputEvent) -> void:
	if screen == Screen.TITLE:
		if event.is_action_pressed("start") and not event.is_echo():
			title_title_reveal_tween.stop()
			music_player.stop()
			background.show()
			play_audio(select_sfx)
			change_screen(Screen.MENU)

func title_poopy_jump(t: float) -> void:
	if t <= 0.03:
		title_poopy_jump_vel -= 10
	title_poopy.position.y += title_poopy_jump_vel
	if title_poopy.position.y > 330:
		title_poopy.position.y = 330
	title_poopy_jump_vel += 50 * (t - title_poopy_last_frametime)
	title_poopy_last_frametime = t

func title_poopy_run(duration: float) -> Tween:
	var tween := create_tween()
	var segment_duration = duration / 8
	tween.pause()
	for i in 2:
		tween.tween_callback(func(): title_poopy.play("dance2"))
		tween.tween_property(title_poopy, "global_position:x", screen_rect.size.x - 90, segment_duration / 2)
		tween.tween_callback(func(): title_poopy.rotation_degrees -= 90)
		tween.tween_property(title_poopy, "global_position:y", 90, segment_duration)
		tween.tween_callback(func(): title_poopy.rotation_degrees -= 90)
		tween.tween_property(title_poopy, "global_position:x", 90, segment_duration)
		tween.tween_callback(func(): title_poopy.rotation_degrees -= 90)
		tween.tween_property(title_poopy, "global_position:y", screen_rect.size.y - 60, segment_duration)
		tween.tween_callback(func(): title_poopy.rotation_degrees -= 90)
		tween.tween_property(title_poopy, "global_position:x", screen_rect.size.x / 2, segment_duration / 2)
	tween.tween_callback(func(): title_poopy.play("armflap"))
	return tween

func title_begin_title_reveal():
	var tween := create_tween()
	title_title_reveal_tween = tween
	tween.tween_interval(4)
	tween.tween_callback(func(): title_logo.modulate.a = 1)
	tween.parallel().tween_property(title_logo, "offset_transform_scale", Vector2(1, 1), 0.5)
	tween.parallel().tween_method(screen_shake, 10, 5, 0.35).set_delay(0.4)
	tween.tween_callback(func(): title_logo.modulate.a = 0)
	tween.tween_callback(func(): title_logo.modulate.a = 1).set_delay(.05)
	tween.tween_interval(.05)
	tween.tween_callback(whiteout.show)
	tween.parallel().tween_property(whiteout, "modulate:a", 1, 0.2)
	tween.tween_callback(func():
		title_logo.texture = title_logo_complete
		title_joke_logo.hide()
		background.show()
		music_player.play()
		title_info_box.show()
		title_poopy.show()
		title_poopy.play("jump")
		var tween_drop_infobox := create_tween()
		tween_drop_infobox.tween_callback(title_info_box.show).set_delay(19)
		tween_drop_infobox.tween_property(title_info_box, "offset_transform_position:y", -10, 1)
		tween_drop_infobox.tween_property(title_info_box, "offset_transform_position:y", -50, .1)
		tween_drop_infobox.tween_interval(.05)
		tween_drop_infobox.tween_property(title_info_box, "offset_transform_position:y", -10, .1)
		tween_drop_infobox.set_trans(Tween.TRANS_CUBIC)
		)
	tween.tween_property(whiteout, "modulate:a", 0, 0.2)
	tween.tween_property(title_poopy, "scale", Vector2(0.3, 0.3), 0.5)
	tween.parallel().tween_method(title_poopy_jump, 0., 1., .5)
	tween.tween_callback(func(): title_poopy.play("idle"))
	tween.tween_interval(3.50 - 1.20)
	tween.tween_callback(func(): title_poopy.play("turn_around"))
	tween.tween_interval(2./6)
	tween.tween_interval(0.25)
	tween.tween_callback(func(): title_poopy.play("armflap"))
	tween.tween_interval(4.98 - 3.75)
	tween.tween_property(whiteout, "modulate:a", 1, 0.2)
	tween.tween_callback(func():
		title_portraits_background.show()
		title_portraits_background.process_mode = Node.PROCESS_MODE_INHERIT)
	tween.tween_property(whiteout, "modulate:a", 0, 0.2)
	tween.tween_interval(8.80 - 5.18)
	tween.tween_callback(title_poopy.play.bind("dance1"))
	tween.tween_interval(10.05 - 8.80)
	tween.tween_callback(title_poopy.play.bind("armflap"))
	tween.tween_interval(11.30 - 10.05)
	tween.tween_subtween(title_poopy_run(1.10))
	# tween.tween_interval(12.40 - 10.85)
	tween.tween_callback(title_poopy.play.bind("armflap"))
	tween.tween_interval(13.90 - 12.40)
	tween.tween_callback(title_poopy.play.bind("dance3"))
	tween.tween_interval(15.05 - 13.90)
	tween.tween_callback(title_poopy.play.bind("armflap"))
	tween.tween_interval(50.28 - 15.05)
	tween.tween_property(audio_stream_player, "volume_linear", 0, .25)
	tween.tween_callback(change_screen.bind(Screen.MENU))
	tween.set_trans(Tween.TRANS_CUBIC)

func screen_shake(intensity: float):
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func change_screen(new_screen: Screen):
	if new_screen == Screen.TITLE:
		title_screen.show()
		menu_screen.hide()
		menu_screen.process_mode = Node.PROCESS_MODE_DISABLED
		level_select_screen.hide()
		level_select_screen.process_mode = Node.PROCESS_MODE_DISABLED
		music_player.stop()
		music_player.stream = title_audio_stream
		title_begin_title_reveal()
	elif new_screen == Screen.MENU:
		whiteout.hide()
		background.show()
		title_screen.hide()
		menu_screen.show()
		menu_screen.process_mode = Node.PROCESS_MODE_INHERIT
		music_player.stream = menu_audio_stream
		music_player.play()
		level_select_screen.hide()
		level_select_screen.process_mode = Node.PROCESS_MODE_DISABLED
	elif new_screen == Screen.LEVEL_SELECT:
		whiteout.hide()
		background.show()
		title_screen.hide()
		menu_screen.hide()
		menu_screen.process_mode = Node.PROCESS_MODE_DISABLED
		if not music_player.stream == menu_audio_stream:
			music_player.stream = menu_audio_stream
			music_player.play()
		elif not music_player.playing:
			music_player.play()
		level_select_screen.show()
		level_select_screen.process_mode = Node.PROCESS_MODE_INHERIT
	screen = new_screen
