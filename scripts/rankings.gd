extends Control
class_name RankingsScreen

@export var pre_reveal_animation_frames: Array[Texture2D]
@export_custom(PROPERTY_HINT_NONE, "suffix:fps") var pre_reveal_animation_fps: float = 12.
@export_group("Sounds")
@export var drumroll_sound: AudioStream

@onready var rankings := Global.get_ranks()
@onready var rank_time_req: LabelSettings = load("uid://cy8xniqmjk0c1")
@onready var main_menu_scene: PackedScene = load("uid://dady2wku1xusy")

@onready var rank_icon: TextureRect = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/RankIcon
@onready var rank_icon_dummy_spacer: Control = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/DummySpacer
@onready var time_label: Label = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/TimeLabel
@onready var ranks_container: GridContainer = $HBoxContainer/MarginContainer/HBoxContainer/ScrollContainer/MarginContainer/RanksContainer
@onready var rank_animation_tr: TextureRect = $HBoxContainer/Sprite
@onready var whiteout: ColorRect = $Whiteout
@onready var portraits_background: PortraitsBackground = $PortraitsBackground
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var rank_animation_animated_texture: AnimatedTexture
var curr_rank: RankDef

func _ready() -> void:
	rank_animation_animated_texture = rank_animation_tr.texture
	var rank_id: int = Global.get_rank()
	curr_rank = Global.get_ranks()[rank_id]
	rank_icon.texture = curr_rank.icon
	var time := Global.get_time()
	var millis := fmod(time, 1) * 1000
	var seconds := fmod(time, 60)
	var minutes := fmod(time, 3600) / 60 
	time_label.text = "Your time: %02d:%02d.%03d" % [minutes, seconds, millis]
	var ranks := Global.get_ranks()
	for rank in ranks:
		if rank.use_time:
			var icon: TextureRect = TextureRect.new()
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var max_time_label: Label = Label.new()
			max_time_label.label_settings = rank_time_req
			icon.texture = rank.small_icon
			var millis2 := fmod(rank.time, 1) * 1000
			var seconds2 := fmod(rank.time, 60)
			var minutes2 := fmod(rank.time, 3600) / 60 
			max_time_label.text = "%02d:%02d.%03d" % [minutes2, seconds2, millis2]
			ranks_container.add_child(icon)
			ranks_container.add_child(max_time_label)
	start_animation_sequence()

func start_animation_sequence():
	# Pre-Reveal animation
	rank_animation_animated_texture.one_shot = true
	rank_animation_animated_texture.pause = true
	rank_animation_animated_texture.frames = len(pre_reveal_animation_frames)
	rank_animation_animated_texture.current_frame = 0
	var frame_duration := 1. / pre_reveal_animation_fps
	var index := 0
	for frame in pre_reveal_animation_frames:
		rank_animation_animated_texture.set_frame_texture(index, frame)
		rank_animation_animated_texture.set_frame_duration(index, frame_duration)
		index += 1
	var tween = create_tween()
	tween.tween_callback(func():
		audio_stream_player.stream = drumroll_sound
		audio_stream_player.play()
		pass)
	tween.tween_await(audio_stream_player.finished)
	tween.tween_callback(func(): rank_animation_animated_texture.pause = false)
	if curr_rank.music_track_1 != null:
		tween.tween_callback(func():
			audio_stream_player.stream = curr_rank.music_track_1
			audio_stream_player.play())
		tween.tween_callback(func():
			rank_icon_dummy_spacer.hide()
			rank_icon.show()).set_delay(1.44)
		tween.tween_property(rank_icon, "offset_transform_scale", Vector2(1, 1), 0.5)
	else:
		tween.tween_callback(func():
			rank_icon_dummy_spacer.hide()
			rank_icon.show())
		tween.tween_property(rank_icon, "offset_transform_scale", Vector2(1, 1), 0.5)
	tween.tween_method(screen_shake, 10, 5, 0.5)
	tween.tween_callback(apply_rank_animation)
	if curr_rank.show_portraits_background != 0:
		if curr_rank.show_portraits_background == 2:
			portraits_background.scroll_speed = 200
		tween.tween_callback(whiteout.show)
		tween.tween_property(whiteout, "modulate:a", 1, 0.2)
		tween.tween_callback(func():
			portraits_background.show()
			portraits_background.process_mode = Node.PROCESS_MODE_INHERIT)
		tween.tween_property(whiteout, "modulate:a", 0, 0.2)
		tween.tween_callback(whiteout.hide)
	if curr_rank.music_track_1 != null:
		tween.tween_await(audio_stream_player.finished)
	if curr_rank.music_track_2 != null:
		tween.tween_callback(func():
			audio_stream_player.stream = curr_rank.music_track_2
			audio_stream_player.play())
	tween.tween_property(ranks_container, "modulate:a", 1, 2)
	if curr_rank.use_walk_off_animation:
		tween.parallel().tween_property(rank_animation_tr, "offset_transform_position:x", -2800, 3)
	tween.set_trans(Tween.TRANS_CUBIC)

func apply_rank_animation():
	var rank := curr_rank
	rank_animation_animated_texture.one_shot = rank.is_animation_one_shot
	rank_animation_animated_texture.current_frame = 0
	rank_animation_animated_texture.pause = false
	var frames := rank.animation_frames
	var fps := rank.animation_fps
	var frame_duration = 1. / fps
	var index := 0
	rank_animation_animated_texture.frames = len(frames)
	for frame in frames:
		rank_animation_animated_texture.set_frame_texture(index, frame)
		rank_animation_animated_texture.set_frame_duration(index, frame_duration)
		index += 1
	if rank.flip_animation:
		rank_animation_tr.flip_h = true

func screen_shake(intensity: float):
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func _input(event: InputEvent) -> void:
	if event.is_action("start"):
		var main_menu: MainMenu = main_menu_scene.instantiate()
		main_menu.start_screen = MainMenu.Screen.MENU
		get_tree().change_scene_to_node(main_menu)
