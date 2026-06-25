extends Area2D

@onready var main: CanvasLayer = get_parent().get_node("InGameOverlay")

func _on_body_entered(body: CharacterBody2D) -> void:
	if body is Player:
		main.stopwatch_paused = true
		Global.add_time(main.time)
		main.calculate_rank()
		main.show_rank()
		print("Dexter: I'm thankful for yams. \nTrinity: Yams? \nDexter: Comfort food.")