extends Control
class_name PauseMenu

@onready var main_menu_prefab: PackedScene = load("uid://dady2wku1xusy")

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var continue_button: Button = $OptionsContainer/ContinueButton
@onready var restart_button: Button = $OptionsContainer/RestartButton
@onready var return_to_menu_button: Button = $OptionsContainer/ReturnToMenuButton
@onready var quit_button: Button = $OptionsContainer/QuitButton

var hud: InGameOverlay

func _ready() -> void:
    continue_button.pressed.connect(_continue)
    restart_button.pressed.connect(_restart)
    return_to_menu_button.pressed.connect(_menu)
    quit_button.pressed.connect(_quit)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("esc"):
        get_viewport().set_input_as_handled()
        _continue()

func _on_show() -> void:
    music_player.play()
    continue_button.grab_focus()

func _continue() -> void:
    hud.hide_pause_menu()

func _restart() -> void:
    get_tree().paused = false
    Global.begin_level_crossfade(Global.current_level)

func _menu() -> void:
    get_tree().paused = false
    var main_menu: MainMenu = main_menu_prefab.instantiate()
    Global.current_level = -1
    main_menu.start_screen = MainMenu.Screen.MENU
    get_tree().change_scene_to_node(main_menu)

func _quit() -> void:
    get_tree().quit()