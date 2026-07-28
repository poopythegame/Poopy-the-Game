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
@export var disable_selection := false
@export_group("Sounds")
@export var left_sfx: Array[AudioStream]
@export var select_sfx: Array[AudioStream]
@export var right_sfx: Array[AudioStream]

@onready var option_prefab: PackedScene = load("uid://cy14air0s7d4u")

@onready var options_container: Control = $VBoxContainer/TitlesContainer
@onready var option_display_container: PanelContainer = $VBoxContainer/PortraitContainer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var viewport_rect: Rect2
var option_display: Control
var option_boxes: Array[PanelContainer]
var half_width: float
var move_tween: Tween
var select_tween: Tween

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

func _preview_option(option: OptionDef) -> Control:
	var texture_rect := TextureRect.new()
	texture_rect.texture = option.portrait
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return texture_rect

func preview_option(option: OptionDef) -> Control:
	var control := _preview_option(option)
	control.custom_minimum_size = Vector2(788, 491)
	control.custom_maximum_size = Vector2(788, 491)
	return control

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not select_tween or not select_tween.is_running():
		if event.is_action_pressed("ui_right") and not event.is_echo():
			switch(selected + 1)
		elif event.is_action_pressed("ui_left") and not event.is_echo():
			switch(selected - 1)
	if event.is_action_pressed("ui_accept") and not disable_selection:
		play_audio(select_sfx)
		select_tween = create_tween()
		select_tween.tween_method(_flicker_option_box, 0, 0, select_sfx[0].get_length())
		select_tween.tween_callback(option_selected.emit.bind(selected))

func _flicker_option_box(_dummy: int) -> void:
	var option_box := option_boxes[selected]
	option_box.visible = not option_box.visible

func _arrange_boxes() -> void:
	var x := 0.
	for box in option_boxes:
		box.position.x = x
		x += 475 + box.get_rect().size.x

func switch(index: int) -> void:
	if index < 0:
		index = 0
	elif index >= len(options):
		index = len(options) - 1
	if index == selected:
		return
	elif index < selected:
		play_audio(left_sfx)
	elif index > selected:
		play_audio(right_sfx)
	if move_tween and move_tween.is_running():
		move_tween.kill()
		option_display.modulate.a = 0
	move_tween = create_tween()
	var option_box := option_boxes[index]
	var option := options[index]
	var final_x := -option_box.position.x - option_box.get_rect().size.x / 2 + half_width
	var new_option_display = preview_option(option)
	new_option_display.modulate.a = 0
	move_tween.tween_property(options_container, "offset_transform_position:x", final_x, .5)
	move_tween.tween_property(option_display, "modulate:a", 0, .25)
	move_tween.tween_callback(func():
		option_display.queue_free()
		option_display = new_option_display
		option_display_container.add_child(option_display))
	move_tween.tween_property(new_option_display, "modulate:a", 1, .25)
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
	if option_display:
		option_display.queue_free()
	option_display = preview_option(option)
	option_display_container.add_child(option_display)
	option_display.modulate.a = 1
	if not visual_only:
		selected = index
