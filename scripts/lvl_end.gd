extends Area2D

@onready var main: CanvasLayer = get_parent().get_node("InGameOverlay")

func _on_body_entered(body: CharacterBody2D) -> void:
	if body is Player:
		main.stopwatch_paused = true
		Global.add_time(main.time)
		Global.current_level = -1
		main.calculate_rank()
		main.show_rank()