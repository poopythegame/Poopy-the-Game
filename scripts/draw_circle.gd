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

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color, false, stroke_width)