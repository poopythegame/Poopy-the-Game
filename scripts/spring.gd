extends StaticBody2D

@export var force: float = 500

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.area_entered.connect(_contact)

func _contact(collision_area: Area2D):
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player and collision_area == player.get_collision_area():
		var player_pos = player.global_position
		var delta = player_pos - global_position
		var dx = abs(delta.x)
		var dy = abs(delta.y)
		if dx > dy:
			delta.y = 0
		elif dy > dx:
			delta.x = 0
		var motion = Vector2.ZERO
		motion = delta.normalized() * force
		player.motion += motion
		player.springing = true
