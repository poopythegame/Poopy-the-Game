extends Area2D

# This function checks if the specific body (Sonic) is inside the circle
func is_player_touching(player_body: Node2D) -> bool:
	# 'overlaps_body' is a built-in Godot function for Area2D
	return overlaps_body(player_body)
