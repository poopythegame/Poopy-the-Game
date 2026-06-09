extends Node2D

@export var decay_time = 3

@onready var circle_drawer = $DrawCircle

var tween: Tween

func _ready() -> void:
    tween = create_tween()
    tween.tween_property(circle_drawer, "color:a", 0, 3)
    tween.tween_callback(_done)
    tween.set_trans(Tween.TRANS_EXPO)
    tween.set_ease(Tween.EASE_IN)

func _done() -> void:
    queue_free()