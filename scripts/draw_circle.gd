@tool
extends Node2D
class_name DrawCircle

@export var stroke_width: float = 5:
	set(value):
		stroke_width = value
		queue_redraw()

@export var radius: float = 100:
	set(value):
		radius = value
		queue_redraw()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()

@export var filled: bool = false:
	set(value):
		filled = value
		queue_redraw()

func _draw() -> void:
	if filled:
		draw_circle(Vector2.ZERO, radius, color, true)
	else:
		draw_circle(Vector2.ZERO, radius, color, false, stroke_width)