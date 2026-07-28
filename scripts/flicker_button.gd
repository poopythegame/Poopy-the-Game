extends Button

var flickering := false
var should_be_visible := true

func _ready() -> void:
	button_down.connect(func(): flickering = true)
	button_up.connect(func(): flickering = false)

func _process(_delta: float) -> void:
	if flickering:
		if should_be_visible:
			modulate.a = 1
		else:
			modulate.a = 0
		should_be_visible = not should_be_visible
	else:
		modulate.a = 1

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			modulate.a = 1