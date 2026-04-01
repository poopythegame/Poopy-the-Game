extends CanvasLayer

# TW: DEXTER REFRENCES/BRAINROT AHEAD!!! AKA how to know I wrote the code: fandom refrences :,(

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var speedlabel: Label = $left/Speedlabel
@onready var sppedlabely: Label = $right/Sppedlabely
@onready var p_rank = $"right/p-rank"
@onready var healthbar = $left/healthbar #won't worry about it rn btw
@onready var minutes_label = $left/HBoxContainer/minutes
@onready var seconds_label = $left/HBoxContainer/seconds
@onready var msec_label = $left/HBoxContainer/msec
var stopwatch_paused := false
@onready var money = $left/coins
var time: float = 0.0
var minutes: int = 0
var seconds: int = 0
var mseconds: int = 0 

func _ready():
	stopwatch_paused = false 
	print("tonight's the night...")

func _process(delta): 
	# coin logic! long as you set the current scene (numerically) in the script of the main node of the desired lvl, it should AUTOMATICALLY work :D
	var lvl = Global.current_level 
	var coins = Global.level_coins.get(lvl, 0)
	money.text = "coins - " + str(coins)
	# p-rank --> WORKS JUST LIKE COINS!
	var prank = Global.level_prank.get(lvl, 0)
	p_rank.text = "p-rank - " + str(prank)
	# stopwatch (time) 
	if Input.is_action_just_pressed("r"): # !!!!! THIS IS FOR THE SAKE OF DEBUGGING NOT A PERMANENT FEATURE !!!!!
		stopwatch_paused = !stopwatch_paused 
	if not stopwatch_paused:
		time += delta
	mseconds = fmod(time, 1) * 100
	seconds = fmod(time, 60)
	minutes = fmod(time, 3600) / 60 
	minutes_label.text = "%02d:" % minutes
	seconds_label.text = "%02d." % seconds
	msec_label.text = "%03d" % mseconds
	
	
func displayspeed(speed, speedy):
	speedlabel.text =  str(abs(int(speed))) + "mph"
	sppedlabely.text = str(-(int(speedy - 50))) + "mph"
