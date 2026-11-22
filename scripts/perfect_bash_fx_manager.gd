extends Node2D
class_name PerfectBashFxManager

const perfect_bash_fx_ttl: float = 0.1
const perfect_bash_fx_max_scale: float = 0.55
const n_particles: int = 1
const fx_sprite_path: String = "uid://j8fbwn6ejy07" 

class PerfectBashFx:
	var sprite: Sprite2D
	var time_left: float
	var done: bool
	func _init(sprite: Sprite2D) -> void:
		self.sprite = sprite
		time_left = perfect_bash_fx_ttl
	static func cubic_beizer_1d(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
		return (1-t)**3*p0 + 3*(1-t)**2*t*p1 + 3*(t-1)*t**2*p2 + t**3*p3
	func update(delta: float) -> void:
		if done: return
		var t := 1 - (time_left / perfect_bash_fx_ttl)
		var scale := cubic_beizer_1d(0, 1, 1, 0, t)
		sprite.scale = Vector2(scale, scale) * perfect_bash_fx_max_scale
		time_left -= delta
		if time_left <= 0:
			sprite.queue_free()
			done = true

var fxes: Array[PerfectBashFx]
var fx_sprite: Texture2D
var player_sprite: AnimatedSprite2D

func _ready() -> void:
	fx_sprite = load(fx_sprite_path)

func find_center_position() -> Vector2:
	return player_sprite.offset * player_sprite.scale

func spawn_particles() -> void:
	for i in n_particles:
		var sprite := Sprite2D.new()
		sprite.texture = fx_sprite
		sprite.position = find_center_position()
		add_child(sprite)
		var fx = PerfectBashFx.new(sprite)
		fxes.append(fx)

func _process(delta: float) -> void:
	for fx in fxes:
		fx.update(delta)
	var not_done := func(e: PerfectBashFx):
		return not e.done
	fxes = fxes.filter(not_done)
