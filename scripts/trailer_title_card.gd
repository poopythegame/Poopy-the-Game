extends Control 

@export var enable_audio := true
@export_enum("Big Farma", "Tutorial") var title_card_variant := 0

@onready var title_card_texture_rect: TextureRect = $TextureRect
@onready var title_card_container: PackedScene = load("uid://cwu1p8ufbbf6n")
@onready var tutorial_title_card = load("uid://byj3fpu1pjuru")
@onready var viewport_rect := get_viewport_rect()
@onready var boost_sound = load("uid://dhjqda2lyu4gx")

var john_person: AnimatedSprite2D
var poopy: AnimatedSprite2D
var tween: Tween
var audio_stream_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

func _ready() -> void:
	var container_instance: Node = title_card_container.instantiate()
	for child in container_instance.get_children():
		child.reparent(self)
	john_person = $JohnPerson
	poopy = $PoopyTheGame
	audio_stream_player = $AudioStreamPlayer
	music_player = $MusicPlayer
	if title_card_variant == 1:
		title_card_texture_rect.texture = tutorial_title_card
	_begin_animation()

func _begin_animation() -> void:
	tween = create_tween()
	john_person.play("helicopter")
	poopy.play("walk")
	if enable_audio:
		music_player.play()
	tween.tween_property(john_person, "position:x", viewport_rect.size.x, 2)
	tween.tween_callback(john_person.hide)
	tween.tween_interval(2 - 3.43/6)
	tween.tween_property(poopy, "position:x", viewport_rect.size.x / 16, 3.43/6)
	tween.tween_callback(func():
		poopy.play("armflap")
	)
	tween.tween_interval(1)
	tween.tween_callback(func():
		poopy.play("run")
		audio_stream_player.stream = boost_sound
		audio_stream_player.play()
	)
	tween.tween_property(poopy, "position:x", viewport_rect.size.x, .25)
	tween.tween_callback(func():
		poopy.hide()
	)
