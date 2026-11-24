extends StaticBody2D
class_name Crate

const destruction_particle_acceleration: float = 100
const destruction_time: float = 1

class DestructionParticle:
	var sprite: Sprite2D
	var init_pos: Vector2
	var trajectory: Vector2
	var acceleration: float
	static func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
		return (1-t)**2*p0 + 2*(1-t)*t*p1 + t**2*p2
	func trajectory_position_at(t: float) -> Vector2:
		var initial := init_pos
		var control_point := trajectory * acceleration 
		control_point.y *= 2
		var final := Vector2(control_point.x, 720)
		return quadratic_bezier(initial, control_point, final, t)
	func _init(init_sprite: Sprite2D, init_acceleration: float) -> void:
		sprite = init_sprite
		init_pos = sprite.position
		trajectory = sprite.position.normalized()
		acceleration = init_acceleration

var area_2d: Area2D
var sprite_2d: Sprite2D
var collision_shape_2d: CollisionShape2D
var destroyed: bool
var destruction_fragments: Array[DestructionParticle]
var destruction_t: float

func _ready() -> void:
	area_2d = $Area2D
	area_2d.area_entered.connect(_handle_area_entered)
	area_2d.area_exited.connect(_handle_area_exit)
	sprite_2d = $Sprite2D
	collision_shape_2d = $CollisionShape2D
	collision_shape_2d.disabled = true
	var destruction_fragments_container: Node = $DestructionFragments
	var destruction_fragments_raw := destruction_fragments_container.get_children()
	for destruction_fragment_cand in destruction_fragments_raw:
		if destruction_fragment_cand is Sprite2D:
			destruction_fragments.append(DestructionParticle.new(destruction_fragment_cand, destruction_particle_acceleration))
	for destruction_fragment in destruction_fragments:
		destruction_fragment.sprite.hide()

func process_collision(player: Player) -> void:
	if abs(player.motion.x) > 450 or player.isattacking:
		destroy(abs(player.motion.x) / 225)
	else:
		collision_shape_2d.set_deferred("disabled", false)
	
func _handle_area_entered(collision_area: Area2D) -> void:
	if destroyed:
		return
	var player: Player = get_tree().get_first_node_in_group("Player")
	player.is_touching_crate = true
	if player and collision_area == player.get_collision_area():
		process_collision(player)

func _handle_area_exit(collision_area: Area2D):
	var player: Player = get_tree().get_first_node_in_group("Player")
	player.is_touching_crate = false
	if player and collision_area == player.get_collision_area():
		collision_shape_2d.set_deferred("disabled", true)
	
func destroy(acceleration: float) -> void:
	destroyed = true
	collision_shape_2d.disabled = true
	sprite_2d.hide()
	for fragment in destruction_fragments:
		fragment.sprite.show()
		fragment.acceleration *= acceleration

func _process(delta: float) -> void:
	if destroyed:
		for particle in destruction_fragments:
			particle.sprite.position = particle.trajectory_position_at(destruction_t)
		destruction_t += delta / destruction_time
		if destruction_t >= 1:
			queue_free()
	else:
		for collision_area in area_2d.get_overlapping_areas():
			var player: Player = get_tree().get_first_node_in_group("Player")
			if player and collision_area == player.get_collision_area():
				process_collision(player)