extends Area2D

@onready var main: InGameOverlay = get_parent().get_node("InGameOverlay")

func _on_body_entered(_body: CharacterBody2D) -> void:
	main.stopwatch_paused = false
	main.show_go_indicator()