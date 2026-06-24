extends Control
class_name MainMenu

@export var labels_slide_time := 2.
@export_category("Level Select")
@export var levels: Array[LevelDesc] = []

enum Screen {
	TITLE,
	MENU,
	CREDITS,
	LEVEL_SELECT,
	OPTIONS,
}

@onready var label_settings: LabelSettings = load("uid://bmtl4xmbt3fao")

@onready var title_screen: MarginContainer = $TitleScreen

@onready var menu_screen: MarginContainer = $Menu
@onready var menu_labels_container: HBoxContainer = $Menu/VBoxContainer/TitlesContainer/Titles

@onready var lavel_select_screen: MarginContainer = $LevelSelect
@onready var level_select_labels_container: Control = $LevelSelect/VBoxContainer/TitlesContainer

var screen := Screen.TITLE
var main_scene: PackedScene

var menu_selected := 1
var menu_slide_tween: Tween
var menu_labels: Array[Node]

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

func _input(event: InputEvent) -> void:
	if screen == Screen.TITLE:
		if event.is_action_pressed("start") and not event.is_echo():
			change_screen(Screen.MENU)
		elif event.is_action_pressed("esc") and not event.is_echo():
			_quit()
	elif screen == Screen.MENU:
		if event.is_action_pressed("left") and not event.is_echo():
			menu_switch(menu_selected - 1)
		elif event.is_action_pressed("right") and not event.is_echo():
			menu_switch(menu_selected + 1)
		elif event.is_action_pressed("ui_accept") and not event.is_echo():
			if menu_selected == 1:
				change_screen(Screen.LEVEL_SELECT)
	elif screen == Screen.LEVEL_SELECT:
		if event.is_action_pressed("left") and not event.is_echo():
			level_select_switch(-1)
		elif event.is_action_pressed("right") and not event.is_echo():
			level_select_switch(1)
		elif event.is_action_pressed("ui_accept") and not event.is_echo():
			begin(levels[level_select_selected])

func menu_switch(new: int):
	menu_selected = new
	if menu_selected < 0:
		menu_selected = 0
	elif menu_selected > 2:
		menu_selected = 2
	if menu_slide_tween:
		menu_slide_tween.kill()
	var width = menu_labels_container.get_rect().size.x / 2
	var label_width = menu_labels[menu_selected].get_rect().size.x / 2
	var index_offset = (menu_selected - 1)
	var offset: float = index_offset * width + -sign(index_offset) * label_width
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
		var offset_right = container_width * (3/2) - label_width_half
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
	get_tree().change_scene_to_packed(level.scene)

func _quit() -> void:
	get_tree().quit()

func change_screen(new_screen: Screen):
	if new_screen == Screen.TITLE:
		title_screen.show()
		menu_screen.hide()
		lavel_select_screen.hide()
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
