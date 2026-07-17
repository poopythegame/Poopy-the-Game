extends Control
class_name MainMenu

@export var labels_slide_time := 2.
@export var start_screen := Screen.TITLE
@export_category("Level Select")

enum Screen {
	TITLE,
	MENU,
	CREDITS,
	LEVEL_SELECT,
	OPTIONS,
}

@onready var label_settings: LabelSettings = load("uid://o04nc50d6jgm")
@onready var title_logo_complete: Texture2D = load("uid://b5w0pc7x5csx5")

@onready var title_screen: MarginContainer = $TitleScreen
@onready var title_logo: TextureRect = $TitleScreen/VBoxContainer/Logo
@onready var title_joke_logo: Label = $TitleScreen/VBoxContainer/JokeLogo
@onready var title_info_box: PanelContainer = $TitleScreen/VBoxContainer/Info
@onready var background: TextureRect = $Background
@onready var whiteout: ColorRect = $Whiteout
@onready var title_theme_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var title_poopy: AnimatedSprite2D = $TitleScreen/VBoxContainer/Logo/PoopyContainer/Poopy
@onready var title_portraits_background: Node2D = $TitleScreen/PortraitsBackground

@onready var menu_screen: MarginContainer = $Menu
@onready var menu_labels_container: HBoxContainer = $Menu/VBoxContainer/TitlesContainer/Titles

@onready var lavel_select_screen: MarginContainer = $LevelSelect
@onready var level_select_labels_container: Control = $LevelSelect/VBoxContainer/TitlesContainer

@onready var levels := Global.levels.levels

var screen := Screen.TITLE
var main_scene: PackedScene

var title_intro_finished := false

var menu_selected := 1
var menu_slide_tween: Tween
var menu_labels: Array[Node]
var menu_initial_offset: Vector2

var level_select_selected := 0
var level_select_slide_tween: Tween
var level_select_labels: Array[Label] = []

func _ready() -> void:
	menu_labels = menu_labels_container.get_children()
	for level in levels:
		var label = Label.new()
		label.label_settings = label_settings
		label.text = level.title
		level_select_labels.append(label)
		level_select_labels_container.add_child(label)
	menu_initial_offset = menu_labels_container.position
	title_portraits_background.process_mode = Node.PROCESS_MODE_DISABLED
	change_screen(start_screen)

func _input(event: InputEvent) -> void:
	if screen == Screen.TITLE:
		if event.is_action_pressed("start") and not event.is_echo() and title_intro_finished:
			change_screen(Screen.MENU)
		elif event.is_action_pressed("esc") and not event.is_echo():
			_quit()
	elif screen == Screen.MENU:
		if event.is_action_pressed("left") and not event.is_echo():
			menu_switch(menu_selected + 1)
		elif event.is_action_pressed("right") and not event.is_echo():
			menu_switch(menu_selected - 1)
		elif event.is_action_pressed("ui_accept") and not event.is_echo():
			if menu_selected == 1:
				change_screen(Screen.LEVEL_SELECT)
	elif screen == Screen.LEVEL_SELECT:
		if event.is_action_pressed("left") and not event.is_echo():
			level_select_switch(-1)
		elif event.is_action_pressed("right") and not event.is_echo():
			level_select_switch(1)
		elif event.is_action_pressed("ui_accept") and not event.is_echo():
			Global.current_level = level_select_selected
			begin(levels[level_select_selected])

func title_begin_title_reveal():
	var tween := create_tween()
	tween.tween_interval(2)
	tween.tween_callback(func(): title_logo.modulate.a = 1)
	tween.parallel().tween_property(title_logo, "offset_transform_scale", Vector2(1, 1), 0.5)
	tween.tween_method(screen_shake, 10, 5, 0.5)
	tween.tween_interval(1)
	tween.tween_callback(whiteout.show)
	tween.parallel().tween_property(whiteout, "modulate:a", 1, 0.2)
	tween.tween_callback(func():
		title_logo.texture = title_logo_complete
		title_joke_logo.hide()
		background.show()
		title_theme_player.play()
		title_info_box.show()
		title_poopy.show()
		title_poopy.play("jump")
		)
	tween.tween_property(whiteout, "modulate:a", 0, 0.2)
	tween.tween_property(title_poopy, "position", Vector2(0, 310), 0.5)
	tween.parallel().tween_property(title_poopy, "scale", Vector2(0.3, 0.3), 0.5)
	tween.tween_callback(func(): title_poopy.play("idle"))
	tween.tween_interval(4.5 - 1.70)
	tween.tween_property(whiteout, "modulate:a", 1, 0.2)
	tween.tween_callback(func():
		title_poopy.play("armflap")
		title_portraits_background.show()
		title_portraits_background.process_mode = Node.PROCESS_MODE_INHERIT)
	tween.tween_property(whiteout, "modulate:a", 0, 0.2)
	# Set finished flag to true in order to enable the Enter key
	tween.tween_callback(func(): title_intro_finished = true)
	tween.set_trans(Tween.TRANS_CUBIC)

func screen_shake(intensity: float):
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func menu_switch(new: int):
	menu_selected = new
	if menu_selected < 0:
		menu_selected = 0
	elif menu_selected > 2:
		menu_selected = 2
	if menu_slide_tween:
		menu_slide_tween.kill()
	var label_width = menu_labels[menu_selected].size.x
	var left_x = (menu_labels_container.size.x - label_width * 2) / 2
	var center_x = (1180 - menu_labels_container.size.x) / 2
	var right_x = (0 - menu_labels_container.size.x) / 2
	var offset: float
	if menu_selected == 0:
		offset = left_x
	elif menu_selected == 1:
		offset = center_x
	elif menu_selected == 2:
		offset = right_x
	menu_slide_tween = create_tween()
	menu_slide_tween.tween_property(menu_labels_container, "position:x", offset, labels_slide_time)
	menu_slide_tween.set_ease(Tween.EASE_IN_OUT)
	menu_slide_tween.set_trans(Tween.TRANS_CUBIC)

func level_select_switch(inc: int):
	level_select_selected += inc
	if level_select_selected < 0:
		level_select_selected = 0
	elif level_select_selected >= levels.size():
		level_select_selected = levels.size() - 1
	if level_select_slide_tween:
		level_select_slide_tween.kill()
	level_select_slide_tween = create_tween()
	var hides: Array[Label] = []
	for i in range(level_select_labels.size()):
		var label := level_select_labels[i]
		var label_width_half = label.get_rect().size.x / 2
		# TODO: make this dynamic
		var container_width = 1180.
		var offset_left = -container_width / 2 - label_width_half
		var offset_prev = 0 - label_width_half
		var offset_curr = container_width / 2 - label_width_half
		var offset_next = container_width - label_width_half
		var offset_right = container_width * (3./2) - label_width_half
		if i == level_select_selected - 1:
			level_select_slide_tween.parallel()
			if label.visible:
				level_select_slide_tween.tween_property(label, "position:x", offset_prev, labels_slide_time)
			else:
				var offset = offset_curr
				if inc == -1:
					offset = offset_left
				label.position.x = offset_prev
				label.show()
				level_select_slide_tween.tween_property(label, "position:x", offset, labels_slide_time)
				hides.append(label)
		elif i == level_select_selected:
			level_select_slide_tween.parallel()
			if label.visible:
				level_select_slide_tween.tween_property(label, "position:x", offset_curr, labels_slide_time)
			else:
				var offset = offset_next
				if inc == -1:
					offset = offset_prev
				label.position.x = offset_curr
				label.show()
				level_select_slide_tween.tween_property(label, "position:x", offset, labels_slide_time)
				hides.append(label)
		elif i == level_select_selected + 1:
			level_select_slide_tween.parallel()
			if label.visible:
				level_select_slide_tween.tween_property(label, "position:x", offset_next, labels_slide_time)
			else:
				var offset = offset_right
				if inc == -1:
					offset = offset_curr
				label.position.x = offset_next
				label.show()
				level_select_slide_tween.tween_property(label, "position:x", offset, labels_slide_time)
				hides.append(label)
		else:
			label.hide()
	for hide in hides:
		level_select_slide_tween.tween_callback(hide.hide)
		level_select_slide_tween.parallel()
	level_select_slide_tween.set_ease(Tween.EASE_IN_OUT)
	level_select_slide_tween.set_trans(Tween.TRANS_CUBIC)
	level_select_slide_tween.play()

func level_select_position_elements():
	if level_select_selected < 0:
		level_select_selected = 0
	elif level_select_selected >= levels.size():
		level_select_selected = levels.size() - 1
	for i in range(level_select_labels.size()):
		var label := level_select_labels[i]
		var label_width_half = label.get_rect().size.x / 2
		# TODO: make this dynamic
		var container_width = 1180.
		var offset_prev = 0 - label_width_half
		var offset_curr = container_width / 2 - label_width_half
		var offset_next = container_width - label_width_half
		if i == level_select_selected - 1:
			label.position.x = offset_prev
		elif i == level_select_selected:
			label.position.x = offset_curr
		elif i == level_select_selected + 1:
			label.position.x = offset_next
		else:
			label.hide()

func begin(level: LevelDesc) -> void:
	Global.reset_coins()
	get_tree().change_scene_to_packed(level.scene)

func _quit() -> void:
	get_tree().quit()

func change_screen(new_screen: Screen):
	if new_screen == Screen.TITLE:
		title_screen.show()
		menu_screen.hide()
		lavel_select_screen.hide()
		title_begin_title_reveal()
	elif new_screen == Screen.MENU:
		title_screen.hide()
		menu_screen.show()
		lavel_select_screen.hide()
	elif new_screen == Screen.LEVEL_SELECT:
		title_screen.hide()
		menu_screen.hide()
		lavel_select_screen.show()
		level_select_position_elements()
	screen = new_screen
