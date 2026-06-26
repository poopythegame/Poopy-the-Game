extends HBoxContainer

@onready var rankings := Global.get_ranks()
@onready var rank_display_scene: PackedScene = load("uid://cxqog80c2q55h")
@onready var main_menu_scene: PackedScene = load("uid://dady2wku1xusy")

@onready var rank_letter_label: Label = $MarginContainer/VBoxContainer/Rank/RankLetter
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var ranks_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/RankingsContainer

func _ready() -> void:
	var rank_id: int = Global.get_rank()
	var curr_rank = Global.get_ranks()[rank_id]
	rank_letter_label.text = curr_rank.letter
	var time := Global.get_time()
	print(time)
	var mseconds := fmod(time, 1) * 100
	var seconds := fmod(time, 60)
	var minutes := fmod(time, 3600) / 60 
	time_label.text = "Your time: %02d:%02d:%03d" % [minutes, seconds, mseconds]
	var ranks := Global.get_ranks()
	for rank in ranks:
		var display: HBoxContainer = rank_display_scene.instantiate()
		var letter_label = display.get_node("RankLetter")
		var max_time_label = display.get_node("MaxTime")
		letter_label.text = rank.letter
		var mseconds2 := fmod(rank.time, 1) * 100
		var seconds2 := fmod(rank.time, 60)
		var minutes2 := fmod(rank.time, 3600) / 60 
		max_time_label.text = "%02d:%02d:%03d" % [minutes2, seconds2, mseconds2]
		ranks_container.add_child(display)

func _input(event: InputEvent) -> void:
	if event.is_action("start"):
		var main_menu: MainMenu = main_menu_scene.instantiate()
		main_menu.start_screen = MainMenu.Screen.MENU
		get_tree().change_scene_to_node(main_menu)
