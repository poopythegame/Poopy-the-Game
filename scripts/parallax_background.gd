extends CanvasLayer

@export var camera: Camera

var parallaxes: Array[Parallax2D] = []

func _ready() -> void:
	for child in get_children():
		if child is Parallax2D:
			parallaxes.append(child)

func _process(delta: float) -> void:
	for parallax in parallaxes:
		parallax.scroll_offset.x = -camera.global_position.x * parallax.scroll_scale.x
