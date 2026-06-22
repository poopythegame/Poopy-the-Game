extends Area2D

@onready var main: CanvasLayer = get_parent().get_node("InGameOverlay")

func _on_body_entered(body: CharacterBody2D) -> void:
	main.stopwatch_paused = false