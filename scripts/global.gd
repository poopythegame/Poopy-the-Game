extends Node

var time := true
var current_level := -1
var coins: int = 0
var is_quitting := false
var fullscreen_colorrect: ColorRect
@onready var levels: LevelsDesc = load("uid://bhtmoith33eb6")
var save_data: SaveData

@onready var quit_sfx: Array[AudioStream] = [load("uid://rtq3b4h4llvf")]

var audio_stream_player: AudioStreamPlayer

func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
	# var not_playing_current_sfx := true
	# for stream in streams:
	# 	if stream == audio_stream_player.stream:
	# 		not_playing_current_sfx = false
	# if not_playing_current_sfx:
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

func _input(event: InputEvent) -> void:
	if event.is_action("esc") and not is_quitting:
		is_quitting = true
		play_audio(quit_sfx)
		await audio_stream_player.finished
		get_tree().quit()
	elif event.is_action_pressed("restart") and not event.is_echo():
		begin_level(current_level)

func _ready() -> void:
	var canvas_layer = CanvasLayer.new()
	fullscreen_colorrect = ColorRect.new()
	fullscreen_colorrect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(fullscreen_colorrect)
	add_child(canvas_layer)
	fullscreen_colorrect.modulate.a = 0
	fullscreen_colorrect.hide()
	canvas_layer.layer = 2000
	var data_dir = OS.get_user_data_dir()
	var save_path = data_dir.path_join("save.res")
	save_data = SaveData.new()
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	# if not FileAccess.file_exists(save_path):
	# 	save_data = SaveData.new()
	# else:
	# 	save_data = ResourceLoader.load(save_path)

func _exit_tree() -> void:
	var data_dir = OS.get_user_data_dir()
	var save_path = data_dir.path_join("save.res")
	ResourceSaver.save(save_data, save_path)

func begin_level(index: int) -> void:
	if index < 0:
		return
	var level := levels.levels[index]
	var scene_tree := get_tree()
	reset_coins()
	var level_music_player: AudioStreamPlayer
	if index != current_level:
		level_music_player = AudioStreamPlayer.new()
		level_music_player.stream = level.music
		level_music_player.name = "MusicPlayer"
		level_music_player.autoplay = true
		level_music_player.volume_db = -5
	else:
		level_music_player = scene_tree.current_scene.get_node("MusicPlayer")
		level_music_player.autoplay = false
		scene_tree.current_scene.remove_child(level_music_player)
	var level_node := level.scene.instantiate()
	level_node.add_child(level_music_player)
	current_level = index
	scene_tree.change_scene_to_node(level_node)


func begin_level_crossfade(index: int) -> void:
	var tween := create_tween()
	fullscreen_colorrect.color = Color.BLACK
	fullscreen_colorrect.show()
	fullscreen_colorrect.modulate.a = 0
	tween.tween_property(fullscreen_colorrect, "modulate:a", 1, .5)
	tween.tween_callback(func(): begin_level(index))
	tween.tween_property(fullscreen_colorrect, "modulate:a", 0, .5)
	tween.tween_callback(fullscreen_colorrect.hide)

func add_coin():
	coins += 1

func reset_coins():
	coins = 0

func set_rank(rank_id: int):
	save_data.ranks[current_level] = rank_id

func add_time(seconds: float) -> void:
	save_data.times[current_level].append(seconds)

func get_time() -> float:
	var times: Array = save_data.times[current_level]
	return times[len(times) - 1]

func get_rank():
	var rank = save_data.ranks[current_level]
	if rank == -1:
		return null
	else:
		return save_data.ranks[current_level] 

func get_ranks() -> Array[RankDef]:
	return levels.levels[current_level].rankings

func get_coins() -> int:
	return coins
