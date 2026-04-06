extends StaticBody2D
class_name Spike

@export var damage: float = 20

@onready var area: Area2D = $Area2D

func _ready() -> void:
    area.body_entered.connect(_contact)

func _contact(body: Node2D):
    print("contact")
    if body is Player:
        var player: Player = body
        if player.global_position.y < global_position.y and player.motion.y > 0:
            player.take_damage(20)
            player.bounce(500)