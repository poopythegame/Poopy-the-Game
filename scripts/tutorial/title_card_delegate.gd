extends TextureRect 

signal animation_finished()

var timer: SceneTreeTimer 
var animation_duration: float

func _begin_animation() -> void:
	timer = get_tree().create_timer(2)
	timer.timeout.connect(_end_animation)

func _end_animation() -> void:
	animation_finished.emit()