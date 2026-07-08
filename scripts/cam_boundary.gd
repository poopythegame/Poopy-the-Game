@tool
extends Node2D
class_name CamBoundary

## Flips the camera boundary marker from facing to the right to restricting the camera to stay to its left.
@export var flip: bool = false

func _ready() -> void:
    add_to_group("cam_boundary")

func _draw() -> void:
    if Engine.is_editor_hint():
        draw_line(Vector2.ZERO, Vector2(0,-75), Color.INDIAN_RED, 3)