extends Node
class_name AfterimageManager

const afterimage_time: float = 0.08
const afterimage_timeout: float = 0.16
const afterimage_base_opacity: float = 0.5

class Afterimage:
	var time_left: float = afterimage_timeout
	var sprite: Sprite2D
	var done: bool 
	func _init(sprite: Sprite2D):
		self.sprite = sprite
	func update(delta_time: float) -> void:
		if done:
			return
		time_left -= delta_time
		sprite.modulate.a = afterimage_base_opacity * (time_left / afterimage_timeout)
		if time_left <= 0:
			done = true
			sprite.queue_free()

var enabled: bool = false
var target: AnimatedSprite2D
var afterimage_timer: float
var afterimages: Array[Afterimage]

func _ready() -> void:
	afterimage_timer = afterimage_time

func create_afterimage() -> void:
	var frame_index := target.frame
	var current_animation := target.animation
	var sprite_frames := target.sprite_frames
	var frame := sprite_frames.get_frame_texture(current_animation, frame_index)
	var sprite := Sprite2D.new()
	sprite.texture = frame
	sprite.global_position = target.global_position
	sprite.offset = target.offset
	sprite.scale = target.scale
	sprite.rotation = target.rotation
	sprite.flip_h = target.flip_h
	sprite.flip_v = target.flip_v
	add_child(sprite)
	var afterimage := Afterimage.new(sprite)
	print("made it")
	afterimages.append(afterimage)

func _process(delta: float) -> void:
	if enabled:
		if afterimage_timer <= 0:
			afterimage_timer = afterimage_time
			create_afterimage()
		else:
			afterimage_timer -= delta
	for afterimage in afterimages:
		afterimage.update(delta)
	var is_running := func(e: Afterimage): return not e.done
	afterimages = afterimages.filter(is_running)
