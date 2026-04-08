extends CharacterBody2D
class_name Enemy

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var anchor: Area2D = $anchor


# --- PHYSICS VARIABLES ---
var isfrozen = false
var motion := Vector2(0, 0)
var rot := 0.0
var grounded := false
var slopeangle := 0.0
var slopefactor := 0.0

# --- POSITIONING & TRAVEL VARIABLES ---
var frozen_origin := Vector2.ZERO # The exact center (start of freeze)
var grid_coords := Vector2.ZERO # Tracks grid steps (e.g. 1,0 or -1,-1)
var next_grid_coords := Vector2.ZERO
var grid_move_tween: Tween = null
var target_position := Vector2.ZERO 
var is_traveling := false 

const GRID_OFFSET = 70.0 
const TRAVEL_SPEED = 800.0 
const ARRIVAL_DISTANCE = 5.0 

# --- HITBOX VARIABLES ---
var hit_cooldown := false
var hit_timer := 0.0

var vulnerable: bool = false

# --- STATS ---
var SLOPEMULT = 2
var GRAVITY = 850
var acc := 3 
const SLIDE_THRESHOLD = 100.0
const BOUNCE_FORGIVENESS_X = 50.0 

func _ready():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		add_collision_exception_with(player)
	if anchor:
		anchor.visible = false
		anchor.monitoring = false
		anchor.monitorable = false

func physics_process_normal(delta):

# --- 1. SURFACE DETECTION ---
	# We need to know if we hit ANY surface (Floor, Wall, or Ceiling), not just the floor.
	var is_touching_surface = false
	var surface_normal = Vector2.UP # Default
	
	if is_on_floor():
		# Always allow standing on the ground (0° / 360°)
		is_touching_surface = true
		surface_normal = get_floor_normal()
	elif is_on_ceiling() or is_on_wall():
		# If we hit a wall or ceiling, strictly check if it's an angled slope.
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider().is_in_group("Player"):
				continue
			var n = col.get_normal()
			
			# A perfectly flat wall has a Y normal of 0.
			# A perfectly flat ceiling has an X normal of 0.
			# We ONLY want to attach if both X and Y are greater than 0 (meaning it's angled).
			if abs(n.x) > 0.01 and abs(n.y) > 0.01: 
				is_touching_surface = true
				surface_normal = n
				break
	# else:
	# 	var space = get_world_2d().space
	# 	var state = PhysicsServer2D.space_get_direct_state(space)
	# 	var query = PhysicsRayQueryParameters2D.create(to_global(Vector2(0,-5)), to_global(Vector2(0,20)))
	# 	var result = state.intersect_ray(query)
	# 	if result:
	# 		is_touching_surface = true
	# 		surface_normal = result.normal
	# 		position = result.position

	# --- 2. CALCULATE SLOPE DATA ---
	if is_touching_surface:
		slopeangle = surface_normal.angle() + (PI/2)
		slopefactor = surface_normal.x
	else:
		slopefactor = 0

	# --- 3. ROTATION VISUALS ---
	$CollisionShape2D.rotation = rot
	$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, rot, 0.25)

	# --- 4. MOMENTUM CONVERSION & LANDING ---
	if is_touching_surface:
		# If we were airborne and just touched a valid surface...
		if not grounded:
			# MOMENTUM CONVERSION
			# We only convert if the slope is steep enough (>= 0.25 radians).
			if abs(slopeangle) >= 0.25 and abs(motion.y) > abs(motion.x): 
				motion.x = motion.y * slopefactor
			
			grounded = true
			
		# Update orientation to match the new surface
		up_direction = surface_normal
		rot = slopeangle
		
	else: 
		# --- LEAVING THE FLOOR ---
		if not $CollisionShape2D/RayCast.is_colliding() and grounded:
			grounded = false
			motion = get_real_velocity()
			rot = 0
			up_direction = Vector2(0, -1)
	# Gravity
	if not is_on_floor() and rot == 0:
		motion.y += GRAVITY * delta
		# The basic Gravity procedure.
		# We only trigger this if you're in the air. Otherwise, your vertical motion- 
		# -would try to increase infinitely while you're on the ground.
	velocity = Vector2(motion.x, motion.y).rotated(rot)

func _physics_process(delta):
	
	# --- 1. TOGGLE FREEZE (Press Only) ---
	# if Input.is_action_just_pressed("enemyfreeze"):
	# 	if not isfrozen:
	# 		engage_freeze()
	
	# --- 2. HANDLE REPOSITIONING INPUT (Hold Only) ---
	if isfrozen and Input.is_action_pressed("enemyfreeze"):
		process_grid_input()

	# --- 3. FROZEN STATE LOGIC ---
	if isfrozen:
		process_frozen_behavior(delta)
	else:
		check_generous_bounce()
		check_player_impact(delta)
		physics_process_normal(delta)

		move_and_slide()
	# slope_stuck_failsafe()

# --- NEW FROZEN LOGIC ---

func engage_freeze():
	if !vulnerable:
		return
	isfrozen = true
	is_traveling = false
	motion = Vector2.ZERO
	velocity = Vector2.ZERO
	
	# Save the center point and reset grid coordinates
	frozen_origin = global_position
	target_position = global_position
	grid_coords = Vector2.ZERO
	
	if anchor:
		anchor.visible = true
		anchor.monitoring = true
		anchor.monitorable = true
		
	$Sprite2D.rotation = 0
	$CollisionShape2D.rotation = 0
	rot = 0
	
	# Ensure collision is ON generally (we manage exceptions later)
	$CollisionShape2D.disabled = false

func disengage_freeze():
	isfrozen = false
	is_traveling = false
	
	# Make sure we interact with player again
	
	if anchor:
		anchor.visible = false
		anchor.monitoring = false
		anchor.monitorable = false

func process_grid_input():
	if is_traveling: return

	var input_vector = Vector2.ZERO
	if Input.is_action_just_pressed("ui_up"): input_vector.y -= 1
	if Input.is_action_just_pressed("ui_down"): input_vector.y += 1
	if Input.is_action_just_pressed("ui_left"): input_vector.x -= 1
	if Input.is_action_just_pressed("ui_right"): input_vector.x += 1
	
	if input_vector != Vector2.ZERO:
		var dx = clamp(input_vector.x, -1, 1)
		var dy = clamp(input_vector.y, -1, 1)
		next_grid_coords.x += dx
		next_grid_coords.y += dy
		next_grid_coords.x = clamp(next_grid_coords.x, -1, 1)
		next_grid_coords.y = clamp(next_grid_coords.y, -1, 1)
		position = frozen_origin + next_grid_coords * GRID_OFFSET
		# If colliding, instantly undo the movement.
		var is_colliding = test_move(global_transform, Vector2.ZERO)
		if is_colliding:
			next_grid_coords = grid_coords
		else:
			if grid_move_tween != null and grid_move_tween.is_running():
				grid_move_tween.kill()
			grid_move_tween = create_tween()
			grid_move_tween.tween_property(self, "grid_coords", next_grid_coords, 0.1)
			grid_move_tween.tween_callback(finish_grid_move)
			grid_move_tween.set_trans(Tween.TRANS_CUBIC)
			grid_move_tween.set_ease(Tween.EASE_IN)
	
	position = frozen_origin + grid_coords * GRID_OFFSET

func finish_grid_move():
	grid_coords = next_grid_coords

func process_frozen_behavior(delta):
	# 1. CHECK PLAYER GRAPPLE STATE
	var player = get_tree().get_first_node_in_group("Player")
	var player_grappling = false
	if player and "is_grappling" in player and player.is_grappling:
		player_grappling = true
	# (Alternatively, check if player is overlapping Anchor if you don't have that var)
	
	# 2. MANAGE GHOSTING
	# If we are moving OR player is grappling -> Player passes through us

	# 3. MOVEMENT vs STATIONARY
	if is_traveling:
		var distance = global_position.distance_to(target_position)
		
		if distance < ARRIVAL_DISTANCE:
			stop_traveling()
		else:
			var direction = global_position.direction_to(target_position)
			velocity = direction * TRAVEL_SPEED
			floor_snap_length = 0.0
			move_and_slide()
			
			if get_slide_collision_count() > 0:
				stop_traveling()
	else:
		# STATIONARY
		velocity = Vector2.ZERO
		
		# IMPORTANT: Now that we are stationary, we allow interaction!
		check_generous_bounce()
		check_player_impact(delta)

func stop_traveling():
	is_traveling = false
	velocity = Vector2.ZERO
	
	# If we hit a wall, we need to update our logic so we don't snap back.
	# We update target_position to where we actually stopped.
	target_position = global_position
	
	# Optional: If you want hitting a wall to "reset" the grid math 
	# so the next move is relative to the wall, you can uncomment this:
	# frozen_origin = global_position
	# grid_coords = Vector2.ZERO

# --- STANDARD FUNCTIONS ---

func check_generous_bounce():
	if hit_cooldown: return
	var player = get_tree().get_first_node_in_group("Player")
	if not player: return
	var is_bounce_state = player.motion.y >= 75 and (Input.is_action_pressed("jump") or Input.is_action_pressed("action"))
	if not is_bounce_state: return

	var dx = abs(player.global_position.x - global_position.x)
	var dy = player.global_position.y - global_position.y 
	if dx < (40 + BOUNCE_FORGIVENESS_X) and dy < 0 and dy > -100:
		perform_bounce(player)

func check_player_impact(delta):
	if hit_cooldown:
		hit_timer -= delta
		if hit_timer <= 0: hit_cooldown = false
		return 
	
	var overlapping_bodies = hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.name == "Player" or body.is_in_group("Player"):
			var Player = body 
			
			if (Player.jumping or Player.isrolling) and (not Player.is_grappling):
				if Player.motion.y >= 75 and (Input.is_action_pressed("jump") or Input.is_action_pressed("action")):
					perform_bounce(Player)
				else:
					launch_enemy(Player)
				vulnerable = true

func perform_bounce(Player):
	Player.motion.y = abs(Player.motion.y) * -1
	if "exitgrapple" in Player: Player.exitgrapple = false
	hit_cooldown = true
	hit_timer = 0.2 

func launch_enemy(Player):
	disengage_freeze() 
	hit_cooldown = true
	hit_timer = 1 
	
	var launch_x = Player.motion.x * 2
	#if abs(launch_x) < 200 and abs(launch_x) >= 25:
		#var dir = sign(global_position.x - Player.global_position.x)
		#if dir == 0: dir = 1
		#launch_x = 200 * dir
	motion.x = launch_x
	
	var vertical_force = Player.motion.y * 1.05
	# if abs(Player.motion.y) < 100 and Player.is_on_floor():
	# 	vertical_force = -300 
	motion.y = vertical_force 
	
	grounded = false
	rot = 0
	position.y -= 8 
	$Sprite2D.rotation = 0
	$CollisionShape2D.rotation = 0

func slope_stuck_failsafe():
	if is_on_floor() and abs(motion.x) > 50 and get_real_velocity().length() < 10:
		position.y -= 4
		motion.x = 0