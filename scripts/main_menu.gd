extends Control

@onready var menu: VBoxContainer = $Controls
@onready var play: Button = $Controls/Play
@onready var quit: Button = $Controls/Quit
@onready var loading_screen: VBoxContainer = $Loading
@onready var loading_indicator: ProgressBar = $Loading/ProgressBar

var main_scene: PackedScene
var load_thread: Thread
var switch_on_finish_load = false

func _ready() -> void:
	play.pressed.connect(_begin)
	quit.pressed.connect(_quit)
	load_thread = Thread.new()
	load_thread.start(_load_main_scene)

func _load_main_scene() -> void:
	main_scene = load("uid://o0rbsha836tg")
	if switch_on_finish_load:
		# Note: Changing scenes from a thread can be tricky! See my note below.
		get_tree().call_deferred("change_scene_to_packed", main_scene)
	else:
		loading_indicator.value = 100

func _begin() -> void:
	if load_thread.is_alive():
		menu.hide()
		loading_screen.show()
		switch_on_finish_load = true
	else:
		get_tree().change_scene_to_packed(main_scene)

func _quit() -> void:
	get_tree().quit()

func _exit_tree():
	if load_thread.is_alive():
		load_thread.wait_to_finish()