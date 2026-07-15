extends Control
class_name RankingsScreen

@onready var rankings := Global.get_ranks()
@onready var rank_display_scene: PackedScene = load("uid://cxqog80c2q55h")
@onready var main_menu_scene: PackedScene = load("uid://dady2wku1xusy")

@onready var rank_icon: TextureRect = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/RankIcon
@onready var time_label: Label = $HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/TimeLabel
@onready var ranks_container: VBoxContainer = $HBoxContainer/MarginContainer/HBoxContainer/ScrollContainer/MarginContainer/RankingsContainer

func _ready() -> void:
	var rank_id: int = Global.get_rank()
	var curr_rank = Global.get_ranks()[rank_id]
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

func _input(event: InputEvent) -> void:
	if event.is_action("start"):
		var main_menu: MainMenu = main_menu_scene.instantiate()
		main_menu.start_screen = MainMenu.Screen.MENU
		get_tree().change_scene_to_node(main_menu)
