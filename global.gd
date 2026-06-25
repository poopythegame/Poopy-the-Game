extends Node

var time = true
var current_level := 0
@onready var levels: LevelsDesc = load("uid://bhtmoith33eb6")
var save_data: SaveData

func _input(event: InputEvent) -> void:
	if event.is_action("esc"):
		get_tree().quit()

func _ready() -> void:
	var data_dir = OS.get_user_data_dir()
	var save_path = data_dir.path_join("save.res")
	if not FileAccess.file_exists(save_path):
		save_data = SaveData.new()
	else:
		save_data = ResourceLoader.load(save_path)

func _exit_tree() -> void:
	var data_dir = OS.get_user_data_dir()
	var save_path = data_dir.path_join("save.res")
	ResourceSaver.save(save_data, save_path)

func add_coin():
	save_data.coins[current_level] += 1

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
	return save_data.coins[current_level]
