extends Area2D

func _ready() -> void:
	pass

# This function checks if the specific body (Sonic) is inside the circle
func is_player_touching(player: Player) -> bool:
	return overlaps_area(player.get_collision_area())
