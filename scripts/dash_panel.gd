extends Node

@export var strength: float = 500
@export var flip: bool = false

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(_contact)
	if flip:
		var sprite: Sprite2D = $Sprite2D
		sprite.flip_h = true

func _contact(body):
	if body is Player:
		var player: Player = body
		var motion: Vector2 = Vector2(1, 0)
		if flip:
			motion.x = -1
		motion *= strength
		player.motion = motion
#testcasecomment
