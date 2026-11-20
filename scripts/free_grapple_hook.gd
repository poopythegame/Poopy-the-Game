extends Area2D
class_name FreeGrappleHook

func is_overlapping_with_ground() -> bool:
	for body in get_overlapping_bodies():
		if body is StaticBody2D:
			return true
	return false

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass
