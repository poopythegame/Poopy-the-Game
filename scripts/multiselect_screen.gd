@tool
extends Control
class_name MultiselectScreen

signal option_selected(index: int)

@export_tool_button("Refresh") var refresh := Callable(self, &"_refresh")
@export var options: Array[OptionDef]:
	set(new_value):
		options = new_value
		if Engine.is_editor_hint():
			for child in options_container.get_children():
				child.queue_free()
			_add_options()
			_create_boxes()
			_arrange_boxes()
			instant_switch(selected)
@export var selected: int:
	set(new_value):
		selected = new_value
		if Engine.is_editor_hint():
			instant_switch(new_value, true)
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var slide_time := 2.
@export_group("Sounds")
@export var left_sfx: Array[AudioStream]
@export var select_sfx: Array[AudioStream]
@export var right_sfx: Array[AudioStream]

@onready var option_prefab: PackedScene = load("uid://cy14air0s7d4u")

@onready var options_container: Control = $VBoxContainer/TitlesContainer
@onready var portrait_display: TextureRect = $VBoxContainer/PortraitContainer/OptionPortrait
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var viewport_rect: Rect2
var option_boxes: Array[PanelContainer]
var half_width: float
var move_tween: Tween

func play_audio(streams: Array[AudioStream]):
	var choice: int = randi_range(0, len(streams) - 1)
	audio_stream_player.stream = streams[choice]
	audio_stream_player.play()

func stop_audio():
	var stream := audio_stream_player.stream
	if stream is AudioStreamWAV:
		if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			audio_stream_player.stop()
	elif stream is AudioStreamOggVorbis:
		if stream.loop:
			audio_stream_player.stop()
	elif stream is AudioStreamMP3:
		if stream.loop:
			audio_stream_player.stop()
	if not audio_stream_player.playing:
		audio_stream_player.stream = null

func _ready() -> void:
	if Engine.is_editor_hint():
		viewport_rect = Rect2(0, 0, ProjectSettings.get("display/window/size/viewport_width"), ProjectSettings.get("display/window/size/viewport_height"))
	else:
		viewport_rect = get_viewport_rect()
	half_width = viewport_rect.size.x / 2 - 20
	_add_options()
	_create_boxes()
	_arrange_boxes()
	instant_switch(selected)

func _refresh():
	for child in options_container.get_children():
		child.queue_free()
	_add_options()
	_create_boxes()
	_arrange_boxes()
	instant_switch(selected)

## Called before option boxes are shown, thus allowing programmatic menu options.
func _add_options() -> void:
	pass

func _create_boxes():
	for option in options:
		var option_box: PanelContainer = option_prefab.instantiate()
		var option_label: Label = option_box.get_node("Label")
		if option.use_label_icon:
			var option_icon_label: TextureRect = option_box.get_node("TextureRect")
			option_icon_label.texture = option.label_icon
			option_label.hide()
			option_icon_label.show()
		else:
			option_label.text = option.title
		options_container.add_child(option_box)
		option_boxes.append(option_box)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("ui_right"):
		switch(selected + 1)
		play_audio(right_sfx)
	elif event.is_action_pressed("ui_left"):
		switch(selected - 1)
		play_audio(left_sfx)
	elif event.is_action_pressed("ui_accept"):
		option_selected.emit(selected)
		play_audio(select_sfx)

func _arrange_boxes() -> void:
	var x := 0.
	for box in option_boxes:
		box.position.x = x
		x += 500 + box.get_rect().size.x

func switch(index: int) -> void:
	if index < 0:
		index = 0
	elif index >= len(options):
		index = len(options) - 1
	if move_tween and move_tween.is_running():
		move_tween.kill()
		portrait_display.modulate.a = 1
	move_tween = create_tween()
	var option_box := option_boxes[index]
	var option := options[index]
	var final_x := -option_box.position.x - option_box.get_rect().size.x / 2 + half_width
	move_tween.tween_property(options_container, "offset_transform_position:x", final_x, .5)
	move_tween.tween_property(portrait_display, "modulate:a", 0, .25)
	move_tween.tween_callback(func(): portrait_display.texture = option.portrait)
	move_tween.tween_property(portrait_display, "modulate:a", 1, .25)
	selected = index

func instant_switch(index: int, visual_only: bool = false) -> void:
	if index < 0:
		index = 0
	elif index >= len(options):
		index = len(options) - 1
	if move_tween:
		move_tween.kill()
	var option_box := option_boxes[index]
	var option := options[index]
	var final_x := -option_box.position.x - option_box.get_rect().size.x / 2 + half_width
	options_container.offset_transform_position.x = final_x
	portrait_display.texture = option.portrait
	portrait_display.modulate.a = 1
	if not visual_only:
		selected = index