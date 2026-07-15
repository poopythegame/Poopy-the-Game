extends CanvasLayer
class_name InGameOverlay

@export var whiteout_time := .5

# TW: DEXTER REFRENCES/BRAINROT AHEAD!!! AKA how to know I wrote the code: fandom refrences :,(

@onready var rankings_scene: PackedScene = load("uid://cpvt7jfaq7yjl")

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var horizontal_speed: Label = $Left/HorizontalSpeed/Readout
@onready var vertical_speed: Label = $Right/VerticalSpeed/Readout
@onready var healthbar: ProgressBar = $Left/HealthBar
@onready var health_label: Label = $Left/HealthBar/HealthNumber
@onready var time_label: Label = $Left/Time/Readout
@onready var whiteout: ColorRect = $Whiteout

var stopwatch_paused := true
@onready var coins_label: Label = $Left/Coins/Readout
var time: float = 0.0
var minutes: int = 0
var seconds: int = 0
var millis: int = 0 

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
	var raw_vspeed = abs(y) - 50
	var raw_hspeed = abs(x)
	var vspeed = raw_vspeed / 30.0 # 30 px = 1 m
	var hspeed = raw_hspeed / 30.0
	horizontal_speed.text = "%0.1f" % hspeed
	vertical_speed.text = "%0.1f" % vspeed

func log_health(value: float, max: float) -> void:
	health_label.text = str(int(value))
	healthbar.value = value / max

func calculate_rank():
	var ranks := Global.get_ranks()
	var rank := len(ranks) - 1
	var best_rank_time := INF
	for i in len(ranks):
		var rank_def := ranks[i]
		if time <= rank_def.time and rank_def.time < best_rank_time:
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
	var rank_display: HBoxContainer = rankings_scene.instantiate()
	get_tree().change_scene_to_node(rank_display)
