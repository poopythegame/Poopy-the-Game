extends CanvasLayer

@onready var horizontal_speedometer: Label = $MarginContainer/UserInterface/HorizontalSpeed/Display
@onready var vertical_speedometer: Label = $MarginContainer/UserInterface/VerticalSpeed/Display
@export var player: Player

func _process(_delta: float) -> void:
	var raw_vspeed = abs(player.motion.y) - 50
	var raw_hspeed = abs(player.motion.x)
	var vspeed = raw_vspeed / 30.0 # 30 px = 1 m
	var hspeed = raw_hspeed / 30.0
	horizontal_speedometer.text = "%0.1f m/s" % hspeed
	vertical_speedometer.text = "%0.1f m/s" % vspeed