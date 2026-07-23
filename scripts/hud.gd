extends CanvasLayer
class_name InGameOverlay

@export var whiteout_time := .5

@onready var rankings_scene: PackedScene = load("uid://cpvt7jfaq7yjl")
@onready var main_menu_prefab: PackedScene = load("uid://dady2wku1xusy")

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var horizontal_speed: Label = $Left/HorizontalSpeed/Readout
@onready var vertical_speed: Label = $Right/VerticalSpeed/Readout
@onready var health_indicator: ColorRect = $Left/HealthBar/ColorRect
@onready var health_label: Label = $Left/HealthBar/HealthNumber
@onready var time_label: Label = $Left/Time/Readout
@onready var whiteout: ColorRect = $Whiteout
@onready var pause_menu_container: Control = $PauseMenuContainer
@onready var pause_menu: MultiselectScreen = $PauseMenuContainer/PauseMenu
@onready var pause_menu_audio_stream_player: AudioStreamPlayer = $PauseMenuContainer/PauseMenu/AudioStreamPlayer
@onready var pause_menu_music_player: AudioStreamPlayer = $PauseMenuContainer/PauseMenu/MusicPlayer

var stopwatch_paused := true
@onready var coins_label: Label = $Left/Coins/Readout
var time: float = 0.0
var minutes: int = 0
var seconds: int = 0
var millis: int = 0 
var quitting := false

func _ready() -> void:
	millis = fmod(time, 1) * 1000
	seconds = fmod(time, 60)
	minutes = fmod(time, 3600) / 60
	var time_readout = "%02d:%02d.%03d" % [minutes, seconds, millis]
	time_label.text = time_readout
	pause_menu.option_selected.connect(_on_pause_menu_option_selected)

func _input(event: InputEvent) -> void:
	if event.is_action("esc"):
		show_pause_menu()

func show_pause_menu() -> void:
	pause_menu_container.show()
	pause_menu_music_player.play()
	get_tree().paused = true

func _on_pause_menu_option_selected(option: int) -> void:
	if quitting:
		return
	pause_menu_music_player.stop()
	if option == 0:
		get_tree().paused = false
		var main_menu: MainMenu = main_menu_prefab.instantiate()
		Global.current_level = -1
		main_menu.start_screen = MainMenu.Screen.MENU
		get_tree().change_scene_to_node(main_menu)
	elif option == 1:
		quitting = true
		await pause_menu_audio_stream_player.finished
		get_tree().quit()
	elif option == 2:
		get_tree().paused = false
		pause_menu_container.hide()
	elif option == 3:
		get_tree().paused = false
		Global.begin_level_crossfade(Global.current_level)

func _process(delta): 
	var level_index = Global.current_level
	var coins = Global.get_coins()
	coins_label.text = "%d" % coins
	if not stopwatch_paused:
		time += delta
		millis = fmod(time, 1) * 1000
		seconds = fmod(time, 60)
		minutes = fmod(time, 3600) / 60
		var time_readout = "%02d:%02d.%03d" % [minutes, seconds, millis]
		time_label.text = time_readout

func display_speed(x, y):
	var raw_vspeed = clamp(abs(y) - 50, 0, INF)
	var raw_hspeed = abs(x)
	var vspeed = raw_vspeed / 30.0 # 30 px = 1 m
	var hspeed = raw_hspeed / 30.0
	horizontal_speed.text = "%0.1f" % hspeed
	vertical_speed.text = "%0.1f" % vspeed

func log_health(value: float, max: float) -> void:
	health_indicator.scale.x = clamp(value / max, 0, 1)

func calculate_rank():
	var ranks := Global.get_ranks()
	var rank := len(ranks) - 1
	var best_rank_time := INF
	for i in len(ranks):
		var rank_def := ranks[i]
		if (time <= rank_def.time or not rank_def.use_time) and rank_def.time < best_rank_time:
			rank = i
			best_rank_time = rank_def.time
	Global.set_rank(rank)

func show_rank():
	whiteout.modulate.a = 0
	whiteout.show()
	var whiteout_tween = create_tween()
	whiteout_tween.tween_property(whiteout, "modulate:a", 1, 2)
	whiteout_tween.tween_callback(_finish_show_rankings)
	whiteout_tween.set_ease(Tween.EASE_OUT)
	whiteout_tween.set_trans(Tween.TRANS_CUBIC)

func _finish_show_rankings():
	var rank_display: RankingsScreen = rankings_scene.instantiate()
	get_tree().change_scene_to_node(rank_display)
