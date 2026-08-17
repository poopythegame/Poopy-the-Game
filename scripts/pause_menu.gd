extends Control
class_name PauseMenu

@onready var main_menu_prefab: PackedScene = load("uid://dady2wku1xusy")

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var continue_button: Button = $OptionsContainer/ContinueButton
@onready var restart_button: Button = $OptionsContainer/RestartButton
@onready var return_to_menu_button: Button = $OptionsContainer/ReturnToMenuButton
@onready var quit_button: Button = $OptionsContainer/QuitButton

@export_group("Sounds")
@export var enter_sfx: Array[AudioStream]
@export var select_sfx: Array[AudioStream]
@export var exit_sfx: Array[AudioStream]

var exiting := false

func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
	audio_stream_player.stream = streams[choice]
	audio_stream_player.play()

var hud: InGameOverlay

func _ready() -> void:
	continue_button.pressed.connect(_continue)
	restart_button.pressed.connect(_restart)
	return_to_menu_button.pressed.connect(_menu)
	if OS.has_feature("web"):
		quit_button.queue_free()
	else:
		quit_button.pressed.connect(_quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		get_viewport().set_input_as_handled()
		_continue()

func _on_show() -> void:
	music_player.play()
	continue_button.grab_focus()
	play_audio(enter_sfx)

func _continue() -> void:
	if exiting:
		return
	hud.hide_pause_menu()
	Global.play_audio(select_sfx)

func _restart() -> void:
	if exiting:
		return
	get_tree().paused = false
	Global.play_audio(select_sfx)
	Global.begin_level_crossfade(Global.current_level)

func _menu() -> void:
	if exiting:
		return
	var tree := get_tree()
	tree.paused = false
	play_audio(select_sfx)
	var main_menu: MainMenu = main_menu_prefab.instantiate()
	Global.current_level = -1
	main_menu.start_screen = MainMenu.Screen.AUX
	var new_parent := main_menu.get_node("AuxCanvasGroup")
	reparent(new_parent)
	name = "Screen"
	Global.play_audio(select_sfx)
	tree.change_scene_to_node(main_menu)
	main_menu.ready.connect(func():
		main_menu.change_screen(MainMenu.Screen.MENU, false, MainMenu.Transition.WIPE)
		music_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		var tween := music_player.create_tween()
		tween.tween_property(music_player, "volume_linear", 0., .5)
		tween.tween_callback(func():
			music_player.process_mode = ProcessMode.PROCESS_MODE_INHERIT
		)
	)

func _quit() -> void:
	if exiting:
		return
	exiting = true
	play_audio(select_sfx)
	await audio_stream_player.finished
	get_tree().quit()
