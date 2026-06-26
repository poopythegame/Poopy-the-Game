extends Resource
class_name SaveData

@export var ranks: Array[int] = []
# This is supposed to be an Array[Array[float]], but for some reason: "Nested typed collections are not supported."
@export var times: Array = []

func _init() -> void:
	var n_slots := len(Global.levels.levels)
	for i in range(n_slots):
		# var n_ranks := len(Global.levels.levels[i].rankings)
		ranks.append(-1)
		times.append([])
