extends StaticBody2D

@export var force: float = 500

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(_contact)

func _contact(body: Node2D):
	if body is Player:
		var player: Player = body
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
