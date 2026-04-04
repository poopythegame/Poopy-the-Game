extends StaticBody2D

@export var force: float = 500

@onready var area: Area2D = $Area2D

func _ready() -> void:
    area.body_entered.connect(_contact)

func _contact(body: Node2D):
    print("contact")
    if body is Player:
        var player: Player = body
        var player_pos = player.global_position
        var motion = Vector2.ZERO
        motion.y -= force
        player.motion += motion
        player.springing = true