extends Area2D

@onready var main: CanvasLayer = get_parent().get_node("InGameOverlay")

func _on_area_entered(collision_area: Area2D) -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player and collision_area == player.get_collision_area():
		main.stopwatch_paused = true
		Global.add_time(main.time)
		main.show_rank()
