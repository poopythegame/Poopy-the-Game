extends Camera2D
class_name Camera

@export_group("Lookahead")
## Whether to enable the camera lookahead.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_lookahead := true
## How far the lookahead shifts the camera to show what's in front of the player.
@export var lookahead_amount: float = 75
## How long it takes for the lookahead to shift the camera.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lookahead_time: float = .5
## The easing curve for lookahead shifts.
@export_exp_easing var lookahead_ease: float = -2
@export_group("Terrain Bobbing")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_terrain_bobbing := false
@export var terrain_bobbing_offset := 50

var frozen := false
var player: Player
var left_boundary: Node2D
var right_boundary: Node2D
var x_offset: float = 0
var next_x_offset: float = 0
var x_offset_t: float = 0
var curr_x_offset: float = 0
const MINSPD = 450

func _ready() -> void:
	var candidates := get_tree().get_nodes_in_group("cam_boundary")
	for node in candidates:
		if node.flip:
			if right_boundary:
				push_error("Cannot have more than one camera left-boundary.")
			right_boundary = node
		else:
			if left_boundary:
				push_error("Cannot have more than one camera left-boundary.")
			left_boundary = node
	player = get_tree().get_first_node_in_group("Player")

func get_rect() -> Rect2:
	var pos := global_position
	var viewport_size := get_viewport_rect().size
	var world_size := viewport_size / zoom
	var top_left := pos - (world_size / 2.)
	return Rect2(top_left, world_size)

func _process(delta: float) -> void:
	if frozen:
		return
	var prev_next_offset = next_x_offset
	if should_disable_lookahead():
		next_x_offset = 0
	elif player.velocity.x > MINSPD:
		next_x_offset = lookahead_amount
	elif player.velocity.x < -MINSPD:
		next_x_offset = -lookahead_amount
	else:
		next_x_offset = 0
	if prev_next_offset != next_x_offset and x_offset_t > 0 and x_offset_t < lookahead_time:
		x_offset = curr_x_offset
		x_offset_t = 0
	curr_x_offset = x_offset
	if next_x_offset != x_offset:
		var t = x_offset_t / lookahead_time
		curr_x_offset = lerp(x_offset, next_x_offset, ease(t, lookahead_ease))
		x_offset_t += delta
		if x_offset_t > lookahead_time:
			x_offset_t = 0
			x_offset = next_x_offset
	global_position = Vector2(player.global_position.x + curr_x_offset, player.global_position.y)
	var rect := get_rect()
	var left_x := rect.position.x
	var right_x := left_x + rect.size.x
	var x_shift_amount := 0.
	if left_boundary:
		if left_boundary.global_position.x > left_x:
			x_shift_amount = left_boundary.global_position.x - left_x
	if right_boundary:
		if right_boundary.global_position.x < right_x:
			x_shift_amount = right_boundary.global_position.x - right_x
	global_position.x += x_shift_amount
	var y_shift_amount := 0.
	if enable_terrain_bobbing:
		var raycast_distance := rect.size.y / 2
		var query = PhysicsRayQueryParameters2D.create(global_position, Vector2(global_position.x, global_position.y + raycast_distance))
		query.hit_from_inside = false
		var hit = get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_y: float = hit["position"].y
			y_shift_amount = raycast_distance - hit_y
	global_position.y -= y_shift_amount

func should_disable_lookahead() -> bool:
	if player.is_grappling:
		return true
	return not enable_lookahead
