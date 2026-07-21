@tool
extends Node2D
class_name PortraitsBackground

class Sprite:
	var sprite_2d: Sprite2D
	var origin: Vector2
	func _init(sprite_2d: Sprite2D, origin: Vector2) -> void:
		self.sprite_2d = sprite_2d
		self.origin = origin

@export_dir var sprites_dir = "res://assets/textures/characters/contour"
@export var margin := 100.
@export var scroll_speed := 5.

var screen_rect: Rect2
var rng := RandomNumberGenerator.new()
var screen_margin := margin / 4
var textures: Array[Texture2D] = []
var sprites: Array[Sprite] = []
var sprite_size: float
var offset := Vector2.ZERO

func get_textures() -> Array[Texture2D]:
	var filenames = ResourceLoader.list_directory(sprites_dir)
	var textures: Array[Texture2D] = []
	for filename in filenames:
		var path = sprites_dir.path_join(filename)
		if ResourceLoader.exists(path):
			var asset = ResourceLoader.load(path)
			if asset is Texture2D:
				textures.append(asset)
	return textures

func create_sprites():
	var vp_size = screen_rect.size
	var x := screen_margin
	var should_carriage_return_on_next := false
	var shift_hor := false
	var y := screen_margin
	var should_terminate_on_next := false
	while true:
		var index := rng.randi_range(0, len(textures) - 1)
		var texture := textures[index]
		var sprite_2d := Sprite2D.new()
		sprite_2d.texture = texture
		sprite_2d.centered = false
		sprite_2d.scale = Vector2(.125, .125)
		sprite_2d.modulate = Color.BLACK
		var sprite_rect = sprite_2d.get_rect() * sprite_2d.global_transform
		sprite_size = sprite_rect.size.x
		var x2 := x
		if shift_hor:
			x2 += margin
		sprite_2d.position = Vector2(x2, y)
		sprites.append(Sprite.new(sprite_2d, sprite_2d.position))
		add_child(sprite_2d)
		x += margin + sprite_rect.size.x
		if should_carriage_return_on_next:
			x = 0
			y += margin + sprite_rect.size.y
			shift_hor = not shift_hor
			should_carriage_return_on_next = false
			if should_terminate_on_next:
				break
		if x > vp_size.x:
			should_carriage_return_on_next = true
		if y > vp_size.y:
			should_terminate_on_next = true

func _ready() -> void:
	if Engine.is_editor_hint():
		screen_rect = Rect2(0, 0, ProjectSettings.get("display/window/size/viewport_width"), ProjectSettings.get("display/window/size/viewport_height"))
	else:
		screen_rect = get_viewport_rect()
	rng.randomize()
	textures = get_textures()
	create_sprites()

func _process(delta: float) -> void:
	var increment = Vector2(scroll_speed, scroll_speed) * delta
	for sprite in sprites:
		var sprite_2d = sprite.sprite_2d
		sprite_2d.position -= increment
		if sprite_2d.position.x < -margin - sprite_size:
			sprite_2d.position.x += screen_rect.size.x + margin + sprite_size
		if sprite_2d.position.y < -margin - sprite_size:
			sprite_2d.position.y += screen_rect.size.y + margin + sprite_size
