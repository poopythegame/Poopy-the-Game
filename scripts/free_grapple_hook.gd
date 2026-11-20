extends Area2D
class_name FreeGrappleHook

const sprite_deploying_path: String = "uid://d1ik6ec8x2cf3"
const sprite_deployed_path: String = "uid://cn1sojfjdgfc4"
const normal_finder_length: float = 20
const normal_finder_steps: int = 16

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_deploying: Texture2D = load(sprite_deploying_path)
@onready var sprite_deployed: Texture2D = load(sprite_deployed_path)

var ground_normal_vector: Vector2
var ground_normal_found: bool = false

func is_overlapping_with_ground() -> bool:
	for body in get_overlapping_bodies():
		if body is StaticBody2D:
			return true
	return false

func find_ground_normal_vector():
	if ground_normal_found:
		return
	var space_state := get_world_2d().direct_space_state
	var nearest_distance := INF
	for step in normal_finder_steps:
		var direction := Vector2.from_angle(TAU * step / normal_finder_steps)
		var query := PhysicsRayQueryParameters2D.create(
			global_position + direction * normal_finder_length,
			global_position - direction * normal_finder_length
		)
		query.exclude = [get_rid()]
		query.collision_mask = collision_mask
		var result := space_state.intersect_ray(query)
		if result:
			var distance := global_position.distance_to(result["position"])
			if distance < nearest_distance:
				nearest_distance = distance
				ground_normal_vector = result["normal"]
				ground_normal_found = true

func _ready() -> void:
	sprite.texture = sprite_deploying

func _process(delta: float) -> void:
	if is_overlapping_with_ground():
		find_ground_normal_vector()
		sprite.texture = sprite_deployed
		if ground_normal_found:
			sprite.global_rotation = (-ground_normal_vector).angle()
