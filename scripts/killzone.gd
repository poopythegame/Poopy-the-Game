extends Area2D

@onready var timer: Timer = $Timer
@onready var player: CharacterBody2D = $"../Player"

func _on_area_entered(collision_area: Area2D):
	var collision_player: Player = get_tree().get_first_node_in_group("Player")
	if collision_player and collision_area == collision_player.get_collision_area():
		timer.start()
		player.deathanim()

func _on_timer_timeout():
	get_tree().reload_current_scene()
