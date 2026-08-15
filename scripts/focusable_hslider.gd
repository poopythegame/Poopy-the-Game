extends HSlider

const FOCUS_STYLEBOX: StyleBoxFlat = preload("uid://c120gqdk7oh14")
@export var halo_offset: float = 4.0

func _ready() -> void:
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	if has_focus() and FOCUS_STYLEBOX:
		var rect: Rect2 = Rect2(Vector2.ZERO, size)
		var halo_rect: Rect2 = rect.grow(halo_offset)
		draw_style_box(FOCUS_STYLEBOX, halo_rect)