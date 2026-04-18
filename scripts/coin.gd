extends Node2D

var used: bool = false

func _ready() -> void:
	var area_2d = $Area2D
	area_2d.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Player and not used:
		# a player picked up the coin
		visible = false
		used = true
		var total_coins = Global.level_coins.get(Global.current_level)
		if not total_coins:
			total_coins = 0
			Global.level_coins.set(Global.current_level, 0)
		total_coins += 1
		Global.level_coins.set(Global.current_level, total_coins)
