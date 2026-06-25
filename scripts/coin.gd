extends Node2D

var used: bool = false

func _ready() -> void:
	var area_2d = $Area2D
	area_2d.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Player and not used:
		# a player picked up the coin
		hide()
		used = true
		# This automatically adds the coin to the correct level "bucket"
		Global.add_coin()
