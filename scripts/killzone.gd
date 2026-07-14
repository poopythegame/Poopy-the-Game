extends Area2D

@onready var timer: Timer = $Timer
@onready var player: CharacterBody2D = $"../Player"

func _on_body_entered(body):
	if body.name == "Player":
		timer.start()
		player.deathanim()

func _on_timer_timeout():
	get_tree().reload_current_scene()
