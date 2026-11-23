extends Area2D

var hook_sprite: Sprite2D

func _ready() -> void:
	hook_sprite = $HookSprite
	hook_sprite.hide()

func is_player_touching(player: Player) -> bool:
	return overlaps_area(player.get_collision_area())

func update_grapple(player: Player) -> void:
	hook_sprite.rotation = player.global_position.direction_to(global_position).angle()
	hook_sprite.show()

func end_grapple() -> void:
	hook_sprite.hide()