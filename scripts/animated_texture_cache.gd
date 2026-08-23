extends Node
class_name AnimatedTextureCache

class AnimatedTextureDef:
	var frames: Array[Texture2D]
	var fps: float
	func _init(frames: Array[Texture2D], fps: float) -> void:
		self.frames = frames
		self.fps = fps
	func get_frame_duration() -> float:
		return 1/fps
	func n_frames() -> int:
		return len(frames)

var cache: Dictionary[String, AnimatedTexture] = {}

func create_or_get(id: String, frames: Array[Texture2D], fps: float) -> AnimatedTexture:
	if id in cache:
		return self.get(id)
	else:
		return create(id, AnimatedTextureDef.new(frames, fps))

func create(id: String, def: AnimatedTextureDef) -> AnimatedTexture:
	var animated_texture := AnimatedTexture.new()
	animated_texture.frames = def.n_frames()	
	var i := 0
	for frame in def.frames:
		animated_texture.set_frame_texture(i, frame)
		animated_texture.set_frame_duration(i, def.get_frame_duration())
		i += 1
	cache[id] = animated_texture
	return animated_texture

func _set(property: StringName, value: Variant) -> bool:
	if value is AnimatedTextureDef:
		var def: AnimatedTextureDef = value
		if not property in cache:
			create(property, def)
		return true
	return false

func _get(property: StringName) -> Variant:
	if property in cache:
		var animation := cache[property]
		animation.pause = false
		animation.current_frame = 0
		return cache[property]
	return null