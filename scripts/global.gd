extends Node

var time := true
var current_level := -1
var coins: int = 0
var is_quitting := false
var fullscreen_colorrect: ColorRect
@onready var levels: LevelsDesc = load("uid://bhtmoith33eb6")
var save_data: SaveData
var is_switching_levels := false
var canvas_layer: CanvasLayer

@onready var quit_sfx: Array[AudioStream] = [load("uid://rtq3b4h4llvf")]

var audio_stream_player: AudioStreamPlayer

func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
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
	canvas_layer = CanvasLayer.new()
	fullscreen_colorrect = ColorRect.new()
	fullscreen_colorrect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(fullscreen_colorrect)
	add_child(canvas_layer)
	fullscreen_colorrect.modulate.a = 0
	fullscreen_colorrect.hide()
	fullscreen_colorrect.z_index = 2000
	canvas_layer.layer = 2000
	var data_dir: String = OS.get_user_data_dir()
	var save_path: String = data_dir.path_join("save.res")
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	if not FileAccess.file_exists(save_path):
		save_data = SaveData.new()
	else:
		save_data = ResourceLoader.load(save_path)

func save_game() -> void:
	var data_dir: String = OS.get_user_data_dir()
	var save_path: String = data_dir.path_join("save.res")
	ResourceSaver.save(save_data, save_path)

func _exit_tree() -> void:
	save_game()

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
		level_music_player.bus = &"Music"
		level_music_player.volume_db = -5
		level_music_player.autoplay = true
	else:
		level_music_player = scene_tree.current_scene.get_node("MusicPlayer")
		level_music_player.autoplay = false
		scene_tree.current_scene.remove_child(level_music_player)
	var level_node := level.scene.instantiate()
	level_node.add_child(level_music_player)
	current_level = index
	scene_tree.change_scene_to_node(level_node)

func begin_level_crossfade(index: int) -> void:
	if index < 0:
		return
	var tween := create_tween()
	fullscreen_colorrect.color = Color.BLACK
	fullscreen_colorrect.show()
	fullscreen_colorrect.modulate.a = 0
	is_switching_levels = true
	get_tree().current_scene.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	tween.tween_property(fullscreen_colorrect, "modulate:a", 1, .5)
	tween.tween_callback(func(): begin_level(index))
	tween.tween_property(fullscreen_colorrect, "modulate:a", 0, .5)
	tween.tween_callback(fullscreen_colorrect.hide)
	tween.tween_callback(func():
		is_switching_levels = false
		get_tree().current_scene.process_mode = ProcessMode.PROCESS_MODE_INHERIT
	)

func begin_level_title_card(index: int):
	if index < 0:
		return
	var tween := create_tween()
	var level := levels.levels[index]
	var scene_tree := get_tree()
	reset_coins()
	var level_node := level.scene.instantiate()
	var camera: Camera2D = level_node.get_node("Camera2D")
	var level_music_player: AudioStreamPlayer
	if index != current_level:
		level_music_player = AudioStreamPlayer.new()
		level_music_player.stream = level.music
		level_music_player.name = "MusicPlayer"
		level_music_player.bus = &"Music"
		level_music_player.volume_db = -5
		var title_card_node: TextureRect
		if level.title_card:
			title_card_node = TextureRect.new()
			title_card_node.texture = level.title_card
			title_card_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_card_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
			title_card_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			title_card_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			title_card_node.stretch_mode = TextureRect.STRETCH_SCALE
			if level.title_card_delegate:
				title_card_node.set_script(level.title_card_delegate)
				if level.jingle:
					title_card_node.animation_duration = level.jingle.get_length()
				else:
					title_card_node.animation_duration = 3.5
			get_tree().current_scene.process_mode = ProcessMode.PROCESS_MODE_DISABLED
			fullscreen_colorrect.color = Color.BLACK
			fullscreen_colorrect.show()
			fullscreen_colorrect.modulate.a = 0
			tween.tween_property(fullscreen_colorrect, "modulate:a", 1, .5)
			tween.tween_callback(func():
				canvas_layer.add_child(title_card_node)
			)
			tween.tween_property(fullscreen_colorrect, "modulate:a", 0, .5)
			tween.tween_callback(func():
				title_card_node._begin_animation()
				audio_stream_player.stream = level.jingle
				level_node.process_mode = Node.PROCESS_MODE_DISABLED
				audio_stream_player.play()
			)
			tween.tween_callback(fullscreen_colorrect.hide)
		elif level.jingle:
			audio_stream_player.stream = level.jingle
			level_node.process_mode = Node.PROCESS_MODE_DISABLED
			audio_stream_player.play()
		if level.jingle:
			tween.tween_await(audio_stream_player.finished)
		else:
			if title_card_node and level.title_card_delegate:
				tween.tween_await(title_card_node.animation_finished)
			level_music_player.autoplay = true
		if title_card_node:
			tween.tween_callback(func():
				fullscreen_colorrect.color = Color.BLACK
				fullscreen_colorrect.modulate.a = 0
				fullscreen_colorrect.show()
			)
			tween.tween_property(fullscreen_colorrect, "modulate:a", 1., .5)
		tween.tween_callback(func():
			is_switching_levels = false
			if title_card_node:
				title_card_node.queue_free()
			camera.process_mode = PROCESS_MODE_ALWAYS 
			get_tree().change_scene_to_node(level_node)
		)
		if title_card_node:
			tween.tween_property(fullscreen_colorrect, "modulate:a", 0., .5)
			tween.tween_callback(func():
				fullscreen_colorrect.hide()
			)
		if level.jingle:
			tween.tween_callback(func():
				level_music_player.play()
			)
		if level.jingle or title_card_node:
			tween.tween_callback(func():
					level_node.process_mode = Node.PROCESS_MODE_INHERIT
			)
		tween.tween_callback(func(): camera.process_mode = Node.PROCESS_MODE_INHERIT)
		is_switching_levels = true
	else:
		level_music_player = scene_tree.current_scene.get_node("MusicPlayer")
		level_music_player.autoplay = false
		scene_tree.current_scene.remove_child(level_music_player)
	level_node.add_child(level_music_player)
	current_level = index

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

func get_best_time(level: int = -1) -> float:
	if level == -1:
		level = current_level
	var best_time = INF
	for time in save_data.times[level]:
		if time < best_time:
			best_time = time
	return best_time

func get_rank(level: int = -1):
	if level == -1:
		level = current_level
	var rank: int = save_data.ranks[level]
	if rank == -1:
		return null
	else:
		return save_data.ranks[current_level] 

func get_ranks() -> Array[RankDef]:
	return levels.levels[current_level].rankings

func get_coins() -> int:
	return coins
