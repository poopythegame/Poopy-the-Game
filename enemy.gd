extends CharacterBody2D

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
var target_position := Vector2.ZERO 
var is_traveling := false 

const GRID_OFFSET = 70.0 
const TRAVEL_SPEED = 800.0 
const ARRIVAL_DISTANCE = 5.0 

# --- HITBOX VARIABLES ---
var hit_cooldown := false
var hit_timer := 0.0

# --- STATS ---
var SLOPEMULT = 2
var GRAVITY = 850
var acc := 3 
const SLIDE_THRESHOLD = 100.0
const BOUNCE_FORGIVENESS_X = 50.0 

func _ready():
	if anchor:
		anchor.visible = false
		anchor.monitoring = false
		anchor.monitorable = false

func _physics_process(delta):
	
	# --- 1. TOGGLE FREEZE (Press Only) ---
	if Input.is_action_just_pressed("enemyfreeze"):
		if not isfrozen:
			engage_freeze()
	
	# --- 2. HANDLE REPOSITIONING INPUT (Hold Only) ---
	if isfrozen and Input.is_action_pressed("enemyfreeze"):
		process_grid_input()

	# --- 3. FROZEN STATE LOGIC ---
	if isfrozen:
		process_frozen_behavior(delta)
		return # Stop standard physics here
		
	# --- 4. STANDARD PHYSICS ---
	check_generous_bounce()
	check_player_impact(delta)
	
	# Slope & Gravity Logic
	if is_on_floor():
		slopeangle = get_floor_normal().angle() + (PI/2)
		slopefactor = get_floor_normal().x
	else:
		slopefactor = 0

	$CollisionShape2D.rotation = rot
	$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, rot, 0.25)

	if is_on_floor():
		if not grounded:
			if abs(slopeangle) >= 0.25 and abs(motion.y) > abs(motion.x):
				motion.x += motion.y * slopefactor
			grounded = true
		up_direction = get_floor_normal()
		rot = slopeangle
	else:
		if grounded:
			grounded = false
			motion = get_real_velocity()
			rot = 0
			up_direction = Vector2(0, -1)

	if not is_on_floor():
		motion.y += GRAVITY * delta
	elif motion.y >= 0: 
		if abs(slopefactor) == 1:
			motion.y = 0

	if is_on_floor():
		if abs(motion.x) < SLIDE_THRESHOLD:
			motion.x = move_toward(motion.x, 0, acc)
		else:
			motion.x = move_toward(motion.x, 0, acc * 0.1)

	if is_on_floor():
		motion.x += (acc * SLOPEMULT) * slopefactor

	var current_rot = rot
	if motion.y < 0: 
		current_rot = 0
		
	velocity = Vector2(motion.x, motion.y).rotated(current_rot)
	move_and_slide()
	slope_stuck_failsafe()

# --- NEW FROZEN LOGIC ---

func engage_freeze():
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
	$CollisionShape2D.set_deferred("disabled", false)

func disengage_freeze():
	isfrozen = false
	is_traveling = false
	
	# Make sure we interact with player again
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		remove_collision_exception_with(player)
	
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
		# Calculate POTENTIAL new grid coordinates
		var new_coords = grid_coords + input_vector
		
		# BOUNDARY CHECK: Only move if x and y are between -1 and 1
		# This creates a 3x3 grid (Center + 1 step in any direction)
		if abs(new_coords.x) <= 1 and abs(new_coords.y) <= 1:
			grid_coords = new_coords
			# Calculate target based on ORIGIN, not current position
			target_position = frozen_origin + (grid_coords * GRID_OFFSET)
			is_traveling = true

func process_frozen_behavior(delta):
	# 1. CHECK PLAYER GRAPPLE STATE
	var player = get_tree().get_first_node_in_group("Player")
	var player_grappling = false
	if player and "is_grappling" in player and player.is_grappling:
		player_grappling = true
	# (Alternatively, check if player is overlapping Anchor if you don't have that var)
	
	# 2. MANAGE GHOSTING
	# If we are moving OR player is grappling -> Player passes through us
	if player:
		if is_traveling or player_grappling:
			add_collision_exception_with(player)
		else:
			remove_collision_exception_with(player)

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
				return 

func perform_bounce(Player):
	Player.motion.y = abs(Player.motion.y) * -1
	if "exitgrapple" in Player: Player.exitgrapple = false
	hit_cooldown = true
	hit_timer = 0.2 

func launch_enemy(Player):
	disengage_freeze() 
	hit_cooldown = true
	hit_timer = 1 
	
	var launch_x = Player.motion.x * 1.3
	#if abs(launch_x) < 200 and abs(launch_x) >= 25:
		#var dir = sign(global_position.x - Player.global_position.x)
		#if dir == 0: dir = 1
		#launch_x = 200 * dir
	motion.x = launch_x
	
	var vertical_force = Player.motion.y * 1.05
	if abs(Player.motion.y) < 100 and Player.is_on_floor():
		vertical_force = -300 
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