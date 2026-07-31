extends TextureRect

signal animation_finished()

@onready var title_card_container: PackedScene = load("uid://cwu1p8ufbbf6n")
@onready var viewport_rect := get_viewport_rect()
@onready var boost_sound = load("uid://dhjqda2lyu4gx")

var animation_duration := -1.
var john_person: AnimatedSprite2D
var poopy: AnimatedSprite2D
var tween: Tween
var audio_stream_player: AudioStreamPlayer

func _ready() -> void:
	if animation_duration == -1:
		push_error("Big Farma: animation_duration was not set.")
		get_tree().quit(1)
		return
	var container_instance: Node = title_card_container.instantiate()
	for child in container_instance.get_children():
		child.reparent(self)
	john_person = $JohnPerson
	poopy = $PoopyTheGame
	audio_stream_player = $AudioStreamPlayer

func _begin_animation() -> void:
	tween = create_tween()
	var segment_duration := animation_duration / 3
	john_person.play("helicopter")
	poopy.play("walk")
	tween.tween_property(john_person, "position:x", viewport_rect.size.x, segment_duration)
	tween.tween_callback(john_person.hide)
	tween.tween_property(poopy, "position:x", viewport_rect.size.x / 16, segment_duration / 2)
	tween.tween_callback(func():
		poopy.play("armflap")
	)
	tween.tween_property(poopy, "position:y", poopy.position.y + 35, segment_duration / 12)
	tween.tween_property(poopy, "position:y", poopy.position.y - 35, segment_duration / 12)
	tween.tween_property(poopy, "position:y", poopy.position.y + 35, segment_duration / 12)
	tween.tween_property(poopy, "position:y", poopy.position.y - 35, segment_duration / 12)
	tween.tween_property(poopy, "position:y", poopy.position.y, segment_duration / 12)
	tween.tween_interval(segment_duration / 12)
	tween.tween_callback(func():
		poopy.play("run")
		audio_stream_player.stream = boost_sound
		audio_stream_player.play()
	)
	tween.tween_property(poopy, "position:x", viewport_rect.size.x, segment_duration / 12 * 4)
	tween.tween_callback(func():
		poopy.hide()
		animation_finished.emit()
	)

func _end_animation() -> void:
	if tween:
		tween.kill()