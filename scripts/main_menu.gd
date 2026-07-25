extends Control
class_name MainMenu

@export var labels_slide_time := 2.
@export var start_screen := Screen.TITLE
@export_group("Sounds")
@export var left_sfx: Array[AudioStream]
@export var select_sfx: Array[AudioStream]
@export var right_sfx: Array[AudioStream]
@export var back_sfx: Array[AudioStream]

enum Transition {
	NONE,
	WIPE,
	CROSSFADE,
}

enum Screen {
	TITLE,
	MENU,
	CREDITS,
	LEVEL_SELECT,
	OPTIONS,
	CHARACTERS,
	RANKINGS,
}

@onready var label_settings: LabelSettings = load("uid://o04nc50d6jgm")
@onready var title_logo_complete: Texture2D = load("uid://b5w0pc7x5csx5")
@onready var title_audio_stream: AudioStreamOggVorbis = load("uid://cotx67p5iwda")
@onready var menu_audio_stream: AudioStreamOggVorbis = load("uid://b26trx8dyw833")

@onready var john_person: TextureRect = $JohnPerson
@onready var whiteout: ColorRect = $Whiteout
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var blackout: ColorRect = $Blackout


@onready var title_screen_cg: CanvasGroup = $TitleScreenCanvasGroup
@onready var title_screen: MarginContainer = $TitleScreenCanvasGroup/Screen
@onready var title_logo: TextureRect = $TitleScreenCanvasGroup/Screen/VBoxContainer/Logo
@onready var title_joke_logo: Label = $TitleScreenCanvasGroup/Screen/VBoxContainer/JokeLogo
@onready var title_info_box: PanelContainer = $TitleScreenCanvasGroup/Screen/VBoxContainer/Info
@onready var title_background: TextureRect = $TitleScreenCanvasGroup/Background
@onready var title_screen_background: TextureRect = $TitleScreenCanvasGroup/Background
@onready var menu_background: TextureRect = $MenuCanvasGroup/Background
@onready var level_select_background: TextureRect = $LevelSelectCanvasGroup/Background
@onready var options_background: TextureRect = $OptionsMenuCanvasGroup/Background
@onready var characters_background: TextureRect = $CharactersCanvasGroup/Background
@onready var title_poopy: AnimatedSprite2D = $TitleScreenCanvasGroup/Screen/VBoxContainer/Logo/PoopyContainer/Poopy
@onready var title_portraits_background: Node2D = $TitleScreenCanvasGroup/Screen/PortraitsBackground
@onready var title_infobox: PanelContainer = $TitleScreenCanvasGroup/Screen/VBoxContainer/Info

@onready var menu_screen_cg: CanvasGroup = $MenuCanvasGroup
@onready var menu_screen: MultiselectScreen = $MenuCanvasGroup/Screen

@onready var level_select_cg: CanvasGroup = $LevelSelectCanvasGroup
@onready var level_select_screen: LevelSelect = $LevelSelectCanvasGroup/Screen

@onready var options_screen_cg: CanvasGroup = $OptionsMenuCanvasGroup
@onready var options_screen: OptionsMenu = $OptionsMenuCanvasGroup/Screen

@onready var characters_screen_cg: CanvasGroup = $CharactersCanvasGroup
@onready var characters_screen: MultiselectScreen = $CharactersCanvasGroup/Screen

@onready var rankings_screen_cg: CanvasGroup = $RankingsCanvasGroup
@onready var rankings_screen: RankingsScreen = $RankingsCanvasGroup/Screen
@onready var rankings_background: TextureRect = $RankingsCanvasGroup/Background

@onready var levels := Global.levels.levels

@onready var screen_cgs: Array[CanvasGroup] = [title_screen_cg, menu_screen_cg, level_select_cg, options_screen_cg, characters_screen_cg, rankings_screen_cg]

var screen := Screen.TITLE
var current_screen_cg: CanvasGroup
var main_scene: PackedScene
var screen_rect: Rect2
var undo_queue: Array[Screen] = []

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
	var window_size := Vector2(ProjectSettings.get("display/window/size/viewport_width"), ProjectSettings.get("display/window/size/viewport_height"))
	title_background.size = window_size
	title_screen_background.size = window_size
	menu_background.size = window_size
	level_select_background.size = window_size
	options_background.size = window_size
	characters_background.size = window_size
	rankings_background.size = window_size
	rankings_screen.main_menu = self
	change_screen(start_screen, false, Transition.NONE)

func _on_menu_option_selected(index: int):
	if index == 0:
		pass
	elif index == 1:
		change_screen(Screen.LEVEL_SELECT, true, Transition.CROSSFADE)
	elif index == 2:
		change_screen(Screen.OPTIONS, true, Transition.CROSSFADE)
	elif index == 3:
		change_screen(Screen.CHARACTERS, true, Transition.CROSSFADE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		var screen = undo_queue.pop_back()
		if screen != null:
			change_screen(screen, false, Transition.NONE)
			play_audio(back_sfx)
	elif screen == Screen.TITLE:
		if event.is_action_pressed("start") and not event.is_echo():
			title_title_reveal_tween.stop()
			music_player.stop()
			# title_background.show()
			play_audio(select_sfx)
			change_screen(Screen.MENU, false, Transition.WIPE)

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
	var segment_duration: float = duration / 8
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
	tween.tween_callback(func():
		title_logo.modulate.a = 0
		# Just sticking this in here
		position = Vector2.ZERO
	)
	tween.tween_callback(func(): title_logo.modulate.a = 1).set_delay(.05)
	tween.tween_interval(.05)
	tween.tween_callback(whiteout.show)
	tween.parallel().tween_property(whiteout, "modulate:a", 1, 0.2)
	tween.tween_callback(func():
		title_logo.texture = title_logo_complete
		title_joke_logo.hide()
		title_background.show()
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
	tween.tween_callback(change_screen.bind(Screen.MENU, false, Transition.WIPE))
	tween.set_trans(Tween.TRANS_CUBIC)

func screen_shake(intensity: float):
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func reveal_screen_cg(screen_cg: CanvasGroup):
	screen_cg.show()
	screen_cg.get_node("Screen").process_mode = Node.PROCESS_MODE_INHERIT
	current_screen_cg = screen_cg

func reveal_screen_cg_wipe(screen_cg: CanvasGroup):
	current_screen_cg.show()
	# A very high z-order
	john_person.z_index = 3002
	john_person.position.x = 0
	john_person.show()
	(current_screen_cg.material as ShaderMaterial).set_shader_parameter("progress", 1.)
	screen_cg.show()
	(screen_cg.material as ShaderMaterial).set_shader_parameter("progress", 0.)
	# A very-high-yet-slightly-lower z-order
	var next_screen_prev_z_index := screen_cg.z_index
	screen_cg.z_index = 3001
	var screen_change_tween := create_tween()
	screen_change_tween.tween_property(screen_cg, "material:shader_parameter/progress", 1.0, 2)
	var orig_size := screen_rect.size.x
	var augmented_size := orig_size + john_person.get_rect().size.x
	var ratio = augmented_size / orig_size
	screen_change_tween.parallel().tween_property(john_person, "position:x", augmented_size, 2 * ratio)
	screen_change_tween.tween_callback(func():
		# Clean up
		john_person.hide()
		current_screen_cg.hide()
		screen_cg.z_index = next_screen_prev_z_index
		screen_cg.get_node("Screen").process_mode = Node.PROCESS_MODE_INHERIT
		current_screen_cg = screen_cg
	)

func reveal_screen_cg_crossfade(screen_cg: CanvasGroup):
	var screen_change_tween := create_tween()
	blackout.show()
	current_screen_cg.show()
	blackout.modulate.a = 0
	screen_change_tween.tween_property(blackout, "modulate:a", 1, 1)
	screen_change_tween.tween_callback(func():
		current_screen_cg.hide()
		screen_cg.show()
	)
	screen_change_tween.tween_property(blackout, "modulate:a", 0, 1)
	screen_change_tween.tween_callback(func():
		# Clean up
		blackout.hide()
		screen_cg.get_node("Screen").process_mode = Node.PROCESS_MODE_INHERIT
		current_screen_cg = screen_cg
	)

func change_screen(new_screen: Screen, record_undo: bool = true, transition_type: Transition = Transition.NONE):
	for s in screen_cgs:
		s.hide()
		s.get_node("Screen").process_mode = Node.PROCESS_MODE_DISABLED
	var screen_cg: CanvasGroup
	if new_screen == Screen.TITLE:
		screen_cg = title_screen_cg
		music_player.stop()
		music_player.stream = title_audio_stream
		title_begin_title_reveal()
	elif new_screen == Screen.MENU:
		whiteout.hide()
		menu_background.show()
		screen_cg = menu_screen_cg
		if not music_player.stream == menu_audio_stream:
			music_player.stream = menu_audio_stream
			music_player.play()
		elif not music_player.playing:
			music_player.play()
	elif new_screen == Screen.LEVEL_SELECT:
		whiteout.hide()
		level_select_background.show()
		if not music_player.stream == menu_audio_stream:
			music_player.stream = menu_audio_stream
			music_player.play()
		elif not music_player.playing:
			music_player.play()
		screen_cg = level_select_cg
	elif new_screen == Screen.CHARACTERS:
		whiteout.hide()
		characters_background.show()
		screen_cg = characters_screen_cg
	elif new_screen == Screen.OPTIONS:
		whiteout.hide()
		options_background.show()
		screen_cg = options_screen_cg
		options_screen._on_enter()
	elif new_screen == Screen.RANKINGS:
		whiteout.hide()
		rankings_background.show()
		screen_cg = rankings_screen_cg
		rankings_screen._on_enter()
	if record_undo:
		undo_queue.append(screen)
	match transition_type:
		Transition.NONE:
			reveal_screen_cg(screen_cg)
		Transition.WIPE:
			reveal_screen_cg_wipe(screen_cg)
		Transition.CROSSFADE:
			reveal_screen_cg_crossfade(screen_cg)
	screen = new_screen
