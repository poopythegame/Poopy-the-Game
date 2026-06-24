extends Node

var time = true
var current_level := 1
var level_coins := {}
var level_prank := {}

# func _ready() -> void:
# 	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_coin():
	var lvl = current_level
	if not level_coins.has(lvl):
		level_coins[lvl] = 0
	level_coins[lvl] += 1
	
func add_prank():
	var lvl = current_level
	if not level_prank.has(lvl):
		level_prank[lvl] = 0
	level_prank[lvl] += 1
