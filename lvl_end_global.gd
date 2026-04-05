extends Area2D

@onready var main: CanvasLayer = get_parent().get_node("main")

func _on_body_entered(body: CharacterBody2D) -> void:
	main.stopwatch_paused = true
	print("Dexter: I'm thankful for yams. \nTrinity: Yams? \nDexter: Comfort food.")
