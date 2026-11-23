extends StaticBody2D
class_name Spike

@export var damage: float = 20

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.area_entered.connect(_contact)

func _contact(collision_area: Area2D):
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player and collision_area == player.get_collision_area():
		if player.global_position.y < global_position.y and player.motion.y > 0:
			player.take_damage(20)
			player.bounce(650)
