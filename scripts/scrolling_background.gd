@tool
extends Control

@export var scroll_speed := 100.
@export var texture: Texture2D:
	set(value):
		for child in get_children():
			child.queue_free()
		displays = _create_displays()
		for display in displays:
			add_child(display)
		texture = value

@onready var viewport_rect := get_viewport_rect()

var displays: Array[TextureRect] = []
var scroll_offset := Vector2.ZERO

func _ready() -> void:
	displays = _create_displays()
	for display in displays:
		add_child(display)

func _create_displays() -> Array[TextureRect]:
	var result: Array[TextureRect] = []
	var original := TextureRect.new()
	original.texture = texture
	original.custom_maximum_size = viewport_rect.size
	original.custom_minimum_size = viewport_rect.size
	result.append(original)
	var top_right := original.duplicate()
	top_right.position.x += viewport_rect.size.x
	result.append(top_right)
	var bottom_left := original.duplicate()
	bottom_left.position.y += viewport_rect.size.y
	result.append(bottom_left)
	var bottom_right := top_right.duplicate()
	bottom_right.position.x += viewport_rect.size.x
	bottom_right.position.y += viewport_rect.size.y
	result.append(bottom_right)
	return result

func _process(delta: float) -> void:
	scroll_offset += Vector2(scroll_speed, scroll_speed) * delta
	scroll_offset.x = wrapf(scroll_offset.x, 0, viewport_rect.size.x)
	scroll_offset.y = wrapf(scroll_offset.y, 0, viewport_rect.size.y)

	for i in displays.size():
		var col := i % 2
		var row := i / 2
		displays[i].position = Vector2(
			col * viewport_rect.size.x - scroll_offset.x,
			row * viewport_rect.size.y - scroll_offset.y
		)	