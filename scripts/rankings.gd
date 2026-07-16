extends Control
class_name RankingsScreen

@export var pre_reveal_animation_frames: Array[Texture2D]
@export_custom(PROPERTY_HINT_NONE, "suffix:fps") var pre_reveal_animation_fps: float = 12.

@onready var rankings := Global.get_ranks()
@onready var rank_display_scene: PackedScene = load("uid://cxqog80c2q55h")
@onready var main_menu_scene: PackedScene = load("uid://dady2wku1xusy")

@onready var rank_icon: TextureRect = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/RankIcon
@onready var rank_icon_dummy_spacer: Control = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/DummySpacer
@onready var time_label: Label = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/TimeLabel
@onready var ranks_container: VBoxContainer = $HBoxContainer/MarginContainer/HBoxContainer/ScrollContainer/MarginContainer/RankingsContainer
@onready var rank_animation_tr: TextureRect = $HBoxContainer/Sprite

var rank_animation_animated_texture: AnimatedTexture
var curr_rank: RankDef

func _ready() -> void:
	rank_animation_animated_texture = rank_animation_tr.texture
	var rank_id: int = 2 # Global.get_rank()
	curr_rank = Global.get_ranks()[rank_id]
	rank_icon.texture = curr_rank.icon
	var time := Global.get_time()
	var millis := fmod(time, 1) * 100
	var seconds := fmod(time, 60)
	var minutes := fmod(time, 3600) / 60 
	time_label.text = "Your time: %02d:%02d.%03d" % [minutes, seconds, millis]
	var ranks := Global.get_ranks()
	for rank in ranks:
		var display: HBoxContainer = rank_display_scene.instantiate()
		var icon: TextureRect = display.get_node("RankIcon")
		var max_time_label: Label = display.get_node("MaxTime")
		icon.texture = rank.icon
		var millis2 := fmod(rank.time, 1) * 100
		var seconds2 := fmod(rank.time, 60)
		var minutes2 := fmod(rank.time, 3600) / 60 
		max_time_label.text = "%02d:%02d.%03d" % [minutes2, seconds2, millis2]
		ranks_container.add_child(display)
	start_animation_sequence()

func start_animation_sequence():
	# Pre-Reveal animation
	rank_animation_animated_texture.one_shot = true
	rank_animation_animated_texture.pause = true
	rank_animation_animated_texture.frames = len(pre_reveal_animation_frames)
	var frame_duration := 1. / pre_reveal_animation_fps
	var index := 0
	for frame in pre_reveal_animation_frames:
		rank_animation_animated_texture.set_frame_texture(index, frame)
		rank_animation_animated_texture.set_frame_duration(index, frame_duration)
		index += 1
	var tween = create_tween()
	tween.tween_callback(func():
		rank_animation_animated_texture.pause = false
		pass).set_delay(2)
	tween.tween_interval(2)
	tween.tween_callback(func():
		rank_icon_dummy_spacer.hide()
		rank_icon.show())
	tween.tween_property(rank_icon, "offset_transform_scale", Vector2(1, 1), 0.5)
	tween.tween_method(screen_shake, 10, 5, 0.5)
	tween.parallel().tween_property(ranks_container, "modulate:a", 1, 2)
	tween.parallel().tween_callback(apply_rank_animation)
	tween.set_trans(Tween.TRANS_CUBIC)
	# tween.set_ease(Tween.EASE_IN_OUT)

func apply_rank_animation():
	rank_animation_animated_texture.one_shot = false
	rank_animation_animated_texture.pause = false
	var rank := curr_rank
	var frames := rank.animation_frames
	var fps := rank.animation_fps
	var frame_duration = 1. / fps
	var index := 0
	rank_animation_animated_texture.frames = len(frames)
	for frame in frames:
		rank_animation_animated_texture.set_frame_texture(index, frame)
		rank_animation_animated_texture.set_frame_duration(index, frame_duration)
		index += 1

func screen_shake(intensity: float):
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func _input(event: InputEvent) -> void:
	if event.is_action("start"):
		var main_menu: MainMenu = main_menu_scene.instantiate()
		main_menu.start_screen = MainMenu.Screen.MENU
		get_tree().change_scene_to_node(main_menu)
