extends CanvasLayer

@onready var speed_label: Label = $MarginContainer/UserInterface/Speed
@export var player: Player

func _process(_delta: float) -> void:
	var raw_speed = player.velocity.length()
	print(raw_speed)
	var speed = raw_speed / 30.0
	speed_label.text = "Speed: %0.1f m/s" % speed