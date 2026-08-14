extends CharacterBody2D
class_name Enemy

@export var dot_spawn_distance = 10
@export var explosion_effect_sprite_frames: SpriteFrames
@export_group("Sounds")
@export var charge_sfx: Array[AudioStream]
@export var hit_sfx: Array[AudioStream]
@export var hurt_sfx: Array[AudioStream]
@export var shock_sfx: Array[AudioStream]
@export var impact_sfx: Array[AudioStream]
@export var shift_begin_sfx: Array[AudioStream]
@export var shift_end_sfx: Array[AudioStream]
@export var freeze_sfx: Array[AudioStream]

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var anchor: Area2D = $anchor
@onready var dot_prefab: PackedScene = load("uid://cq2gsyvw602v0")

# --- PHYSICS VARIABLES ---
var isattacking = false
var isfrozen = false
var motion := Vector2(0, 0)
var rot := 0.0
var grounded := false
var slopeangle := 0.0
var slopefactor := 0.0

# --- ATTACK & PREP VARIABLES ---
@onready var prep_timer: Timer = $PrepTimer
var spotted_player: bool = false
var is_preparing: bool = false
var shockdone = false #used to indicate if the shock ANIMATION is finished


# --- POSITIONING & TRAVEL VARIABLES ---
var frozen_origin := Vector2.ZERO # The exact center (start of freeze)
var grid_coords := Vector2.ZERO # Tracks grid steps (e.g. 1,0 or -1,-1)
var next_grid_coords := Vector2.ZERO
var grid_move_tween: Tween = null
var target_position := Vector2.ZERO 
var is_traveling := false
var freeze_ghost_timer := 0.0

const GRID_OFFSET = 85.0 
const TRAVEL_SPEED = 1800.0 
const ARRIVAL_DISTANCE = 5.0 

# --- HITBOX VARIABLES ---
var hit_cooldown := false
var hit_timer := 0.0

var vulnerable: bool = false
var spawning_dots: bool = false
var distance_since_last_dot_spawn: float = 0
var prev_pos: Vector2
var node_spawn_host: Node
var prev_grid_input: Vector2 = Vector2.ZERO
var player_raw_motion = null

# --- STATS ---
var SLOPEMULT = 2
var GRAVITY = 850
var attackacc := 15
var acc := 3 
var dec := 2.6
const SLIDE_THRESHOLD = 100.0
const BOUNCE_FORGIVENESS_X = 50.0
const AIRDRAG = 1.3
const topspeed = 400.0

enum TestResult {
	LAUNCH,
	BOUNCE,
	NOOP
}

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
	# var not_playing_current_sfx := true
	# for stream in streams:
	# 	if stream == audio_stream_player.stream:
	# 		not_playing_current_sfx = false
	# if not_playing_current_sfx:
	audio_stream_player.stream = streams[choice]
	audio_stream_player.play()

# mutlistreams: Array[Array[AudioStream]]
func play_all_audio_multiselect(multistreams: Array[Array]):
	var streams: Array[AudioStream] = []
	for multistream: Array[AudioStream] in multistreams:
		var choice: int = randi_range(0, len(multistream) - 1)
		streams.append(multistream[choice])
	var polystream: AudioStreamPolyphonic = AudioStreamPolyphonic.new()
	audio_stream_player.stream = polystream
	audio_stream_player.play()
	var playback: AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	for stream in streams:
		playback.play_stream(stream)

func stop_audio():
	var stream: AudioStream = audio_stream_player.stream
	if stream is AudioStreamWAV:
		if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			audio_stream_player.stop()
	elif stream is AudioStreamOggVorbis:
		if stream.loop:
			audio_stream_player.stop()
	elif stream is AudioStreamMP3:
		if stream.loop:
			audio_stream_player.stop()
	if not audio_stream_player.playing:
		audio_stream_player.stream = null

func _ready():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		add_collision_exception_with(player)
	if anchor:
		anchor.visible = false
		anchor.monitoring = false
		anchor.monitorable = false
	node_spawn_host = get_tree().current_scene

func physics_process_normal(delta):
# --- 1. SURFACE DETECTION ---
	var is_touching_surface: bool = false
	var surface_normal: Vector2 = Vector2.UP 
	
	if is_on_floor():
		is_touching_surface = true
		surface_normal = get_floor_normal()
	elif is_on_ceiling() or is_on_wall():
		for i in get_slide_collision_count():
			var col: KinematicCollision2D = get_slide_collision(i)
			if col.get_collider().is_in_group("Player"):
				continue
			var n: Vector2 = col.get_normal()
			
			if abs(n.x) > 0.01 and abs(n.y) > 0.01:
				is_touching_surface = true
				surface_normal = n
				break

	# --- 2. CALCULATE SLOPE DATA ---
	if is_touching_surface:
		slopeangle = surface_normal.angle() + (PI/2)
		slopefactor = surface_normal.x
	else:
		slopefactor = 0

	# --- 3. ROTATION VISUALS ---
	$CollisionShape2D.rotation = rot
	sprite_2d.rotation = lerp_angle(sprite_2d.rotation, rot, 0.25)

	# --- 4. MOMENTUM CONVERSION & LANDING ---
	if is_touching_surface:
		if not grounded:
			if abs(slopeangle) >= 0.25 and abs(motion.y) > abs(motion.x): 
				motion.x = motion.y * slopefactor
			grounded = true
			
		up_direction = surface_normal
		rot = slopeangle
		
	else: # If not on the floor anymore...
		# Reset Rotation and apply Momentum
		if not $CollisionShape2D/RayCast.is_colliding() and grounded:
			grounded = false
			
			motion = get_real_velocity()
			# Set your motion to your actual velocity.
			## This is what converts your momentum when you fly off a slope.
			
			rot = 0
			up_direction = Vector2(0, -1)
			# Set your Rotation and Up Direction to their defaults.

	
	if grounded:
		spawning_dots = false

# --- 5. GRAVITY ---
	if not is_on_floor() and rot == 0:
		motion.y += GRAVITY * delta
	else:
		motion.y = 0
		#if abs(slopefactor) == 1: 
			#motion.y = 0
		#else:
		#	motion.y = 50

#---- 6. Enemy attack loop

	var player: Node = get_tree().get_first_node_in_group("Player")
	
	var direction = sign(player.global_position.x - global_position.x)

	if abs(motion.x) != 0:
		# If moving right (1), point right. If moving left (-1), point left.
		# Multiply by whatever distance your raycast needs to reach (e.g., 20 pixels)
		$CollisionShape2D/WallCast.target_position.x = 7.0 * sign(motion.x)
	
	if isattacking:
		var overlapping_bodies: Array[Node2D] = hitbox.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.name == "Player" or body.is_in_group("Player"):
				if (player.jumping or player.isrolling) and not player.is_grappling:
					pass
				else:
					isattacking = false
					is_preparing = true
					prep_timer.start()
					
					player.take_damage(20)
					player.bounce(650)
					play_audio(hit_sfx)
					
	if vulnerable:
		isattacking = false


# Always check if the player exists before trying to read their position!
	if player:
		var distance_from_player = abs(player.global_position.x - global_position.x)
		
		var vertical_distance_from_player = abs(player.global_position.y - global_position.y)
		
		# 1. Player is in range and enemy is allowed to attack
		if not vulnerable:
			
			# If this is the exact moment the enemy first spots the player, start the node!
			if (distance_from_player < 200 and vertical_distance_from_player < 200):
				if not spotted_player:
					spotted_player = true
					is_preparing = true
					play_audio(shock_sfx)
					prep_timer.start() # Starts the 2-second countdown in the background
			
			# 2. Check if we are still preparing
			if is_preparing:
				# Keep the enemy standing still while the timer runs
				if is_on_floor() and abs(slopefactor) < 0.25: 
					motion.x = move_toward(motion.x, 0, attackacc * 2)
					
			# 3. Timer is finished! Charge at the player!
			elif (not is_preparing) and spotted_player:
				
				if not isattacking:
					play_audio(charge_sfx)
				isattacking = true
				
				if direction == sign(motion.x) or motion.x == 0:
					
					$AnimatedSprite2D.play("run")
					$AnimatedSprite2D.speed_scale = clamp(abs(motion.x)/90, 0.5, 8)
					
					if abs(motion.x) <= topspeed: 
						motion.x += attackacc * direction
							
				else:
					$AnimatedSprite2D.play("skid")
					$AnimatedSprite2D.speed_scale = clamp(abs(motion.x)/90, 1, 8)
					
					if abs(slopefactor) < 0.4: 
						motion.x += dec * direction * 2
					else: 
						motion.x += attackacc * direction
	########################################################

# --- 7. SLOPES & MOMENTUM (THE FIXES) ---

	# Slope Acceleration (Matches Player)
	if is_on_floor():
		motion.x += (acc * SLOPEMULT) * slopefactor

	# Flat Ground Friction (No Input State)
	if is_on_floor() and abs(slopefactor) < 0.25: 
		motion.x = move_toward(motion.x, 0, acc - 1)
	
	velocity = Vector2(motion.x, motion.y).rotated(rot)
	
	#WALL STOPPER
	if is_on_wall() and $CollisionShape2D/WallCast.is_colliding() and not vulnerable: # If you bump into a wall...
		if not grounded:
			motion.x = 0
		elif grounded:
			var ref_angle = asin(abs(slopefactor))
			if (ref_angle <= 0.1):
				motion.x = 0
		# Stop moving.
	
# --- 8. SHOCK ANIMATION

	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true
	
	if vulnerable:
		$AnimatedSprite2D.play("vulnerable")
		
	elif is_preparing:
		if shockdone == false:
			$AnimatedSprite2D.play("shock")
		else:
			$AnimatedSprite2D.play("run")

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
		prev_pos = global_position
		# check_generous_bounce()
		physics_process_normal(delta)
		check_player_impact(delta)

		move_and_slide()
		if spawning_dots:
			var dist: float = global_position.distance_to(prev_pos)
			distance_since_last_dot_spawn += dist
			if distance_since_last_dot_spawn > dot_spawn_distance:
				distance_since_last_dot_spawn = 0
				var dot: Node2D = dot_prefab.instantiate()
				dot.global_position = global_position
				node_spawn_host.add_child(dot)

	# slope_stuck_failsafe()

# --- NEW FROZEN LOGIC ---

func engage_freeze():
	if !vulnerable:
		return
	isfrozen = true
	is_traveling = false
	motion = Vector2.ZERO
	velocity = Vector2.ZERO
	
	# --- NEW: Start the 0.2s invulnerability timer ---
	var overlapping_bodies := hitbox.get_overlapping_bodies()
	var has_player := false
	for body in overlapping_bodies:
		if body.is_in_group("Player"):
			has_player = true
	if has_player:
		freeze_ghost_timer = 0.2
	else:
		freeze_ghost_timer = 0
	
	frozen_origin = global_position
	target_position = global_position
	grid_coords = Vector2.ZERO
	next_grid_coords = Vector2.ZERO
	prev_grid_input = Vector2.ZERO
	
	if anchor:
		anchor.visible = true
		anchor.monitoring = true
		anchor.monitorable = true
		
	sprite_2d.rotation = 0
	$CollisionShape2D.rotation = 0
	rot = 0
	
	$CollisionShape2D.disabled = false
	hit_timer = 0
	play_audio(freeze_sfx)

func disengage_freeze():
	isfrozen = false
	is_traveling = false
	
	# --- NEW: Restore default pass-through state when unfrozen ---
	var player: Node = get_tree().get_first_node_in_group("Player")
	if player and not player in get_collision_exceptions():
		add_collision_exception_with(player)
		
	hitbox.set_deferred("monitoring", true)
	
	if anchor:
		anchor.visible = false
		anchor.monitoring = false
		anchor.monitorable = false

func process_grid_input():
	if is_traveling: return

	# --- NEW: PREVENT GRID MOVE WHILE GRAPPLING ---
	var player: Node = get_tree().get_first_node_in_group("Player")
	if player and "is_grappling" in player and player.is_grappling:
		return # Deny input entirely if player is attached

	var input_vector: Vector2 = Vector2.ZERO
	var sound: int = 0
	if Input.is_action_pressed("grid_up"):
		input_vector.y -= 1
		sound = 1
	if Input.is_action_pressed("grid_down"):
		input_vector.y += 1
		sound = 2
	if Input.is_action_pressed("grid_left"):
		input_vector.x -= 1
		sound = 1
	if Input.is_action_pressed("grid_right"): 
		input_vector.x += 1
		sound = 2
	
	if input_vector != prev_grid_input:
		if sound == 1:
			play_audio(shift_begin_sfx)
		elif sound == 2:
			play_audio(shift_end_sfx)
	var new_axis_x := prev_grid_input.x == 0 and input_vector.x != 0
	var new_axis_y := prev_grid_input.y == 0 and input_vector.y != 0
	var new_axis := new_axis_x or new_axis_y
	prev_grid_input = input_vector

	if grid_move_tween == null or not grid_move_tween.is_running() or new_axis:
		if input_vector != Vector2.ZERO:
			var dx = clamp(input_vector.x, -1, 1)
			var dy = clamp(input_vector.y, -1, 1)
			next_grid_coords.x += dx
			next_grid_coords.y += dy
			next_grid_coords.x = clamp(next_grid_coords.x, -1, 1)
			next_grid_coords.y = clamp(next_grid_coords.y, -1, 1)
			var offset := (frozen_origin + next_grid_coords * GRID_OFFSET) - position
			print(offset)
			var is_colliding: bool = test_move(global_transform, offset)
			if is_colliding:
				next_grid_coords = grid_coords
			else:
				grid_move_tween = create_tween()
				grid_move_tween.tween_property(self, "grid_coords", next_grid_coords, 0.1)
				grid_move_tween.tween_callback(finish_grid_move)
				grid_move_tween.set_trans(Tween.TRANS_CUBIC)
				grid_move_tween.set_ease(Tween.EASE_IN)
	
	position = frozen_origin + grid_coords * GRID_OFFSET

func finish_grid_move():
	grid_coords = next_grid_coords

func process_frozen_behavior(delta):
	# --- NEW: TICK GHOST TIMER ---
	if freeze_ghost_timer > 0:
		freeze_ghost_timer -= delta

	# 1. CHECK PLAYER GRAPPLE STATE
	var player: Node = get_tree().get_first_node_in_group("Player")
	var player_grappling: bool = false
	if player and "is_grappling" in player and player.is_grappling:
		player_grappling = true
	
	# 2. MANAGE GHOSTING
	# We ghost if we are traveling, if the 0.2s timer is active, or if player is grappling.
	var should_ghost: bool = is_traveling or (freeze_ghost_timer > 0) or player_grappling
	
	if player:
		if should_ghost:
			# Disable physical collisions and hitbox interactions
			if not player in get_collision_exceptions():
				add_collision_exception_with(player)
			hitbox.set_deferred("monitoring", false)
		else:
			# Become a solid, interactable object
			if player in get_collision_exceptions():
				remove_collision_exception_with(player)
			hitbox.set_deferred("monitoring", true)

	# 3. MOVEMENT vs STATIONARY
	if is_traveling:
		if anchor and anchor.visible:
			anchor.visible = false
			anchor.monitoring = false
			anchor.monitorable = false

		var distance: float = global_position.distance_to(target_position)
		
		if distance < ARRIVAL_DISTANCE:
			stop_traveling()
		else:
			var direction: Vector2 = global_position.direction_to(target_position)
			velocity = direction * TRAVEL_SPEED
			floor_snap_length = 0.0
			move_and_slide()
			
			if get_slide_collision_count() > 0:
				stop_traveling()
	else:
		# STATIONARY
		if anchor and not anchor.visible:
			anchor.visible = true
			anchor.monitoring = true
			anchor.monitorable = true

		# IMPORTANT: Only test for impact if we are NOT currently ghosting!
		if not should_ghost:
			if test_player_impact(delta) == TestResult.LAUNCH:
				disengage_freeze()
				launch_enemy(player)
			elif test_player_impact(delta) == TestResult.BOUNCE:
				perform_bounce(player)

func stop_traveling():
	is_traveling = false
	velocity = Vector2.ZERO
	target_position = global_position
	
	# --- NEW: GUARANTEE ANCHOR REACTIVATES ON ARRIVAL ---
	if anchor:
		anchor.visible = true
		anchor.monitoring = true
		anchor.monitorable = true
	
	# Optional: If you want hitting a wall to "reset" the grid math 
	# so the next move is relative to the wall, you can uncomment this:
	# frozen_origin = global_position
	# grid_coords = Vector2.ZERO

func check_player_impact(delta):
	if hit_cooldown:
		hit_timer -= delta
		if hit_timer <= 0: hit_cooldown = false
		return
	
	var overlapping_bodies: Array[Node2D] = hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.name == "Player" or body.is_in_group("Player"):
			var player: Player = body 
			
			if (player.jumping or player.isrolling) and (not player.is_grappling):
				if player.motion.y >= 75 and (Input.is_action_pressed("jump") or Input.is_action_pressed("action")):
					perform_bounce(player)
				else:
					launch_enemy(player)
				vulnerable = true

func test_player_impact(_delta: float) -> TestResult:
	var overlapping_bodies: Array[Node2D] = hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.name == "Player" or body.is_in_group("Player"):
			var player: Player = body 
			
			if (player.jumping or player.isrolling) and (not player.is_grappling):
				if player.motion.y >= 75 and (Input.is_action_pressed("jump") or Input.is_action_pressed("action")):
					return TestResult.BOUNCE
				else:
					return TestResult.LAUNCH
	return TestResult.NOOP

func perform_bounce(player: Player):
	player_raw_motion = player.velocity
	player.motion.y = abs(player.motion.y) * -1
	if "exitgrapple" in player: player.exitgrapple = false
	player.canstomp = true
	player.canairdash = true
	hit_cooldown = true
	hit_timer = 0.2 
	show_damage_fx()

func launch_enemy(player):
	hit_cooldown = true
	hit_timer = 1
	var player_motion: Vector2 = player.velocity
	if player_raw_motion != null:
		player_motion = player_raw_motion
		player_raw_motion = null
	
	var launch_x: float = player_motion.x * 1.35
	#if abs(launch_x) < 200 and abs(launch_x) >= 25:
		#var dir = sign(global_position.x - player.global_position.x)
		#if dir == 0: dir = 1
		#launch_x = 200 * dir
	motion.x = launch_x
	
	var vertical_force: float = player_motion.y * 1.05
	# if abs(player.motion.y) < 100 and player.is_on_floor():
	# 	vertical_force = -300 
	motion.y = vertical_force	
	grounded = false
	rot = 0
	position.y -= 8 
	sprite_2d.rotation = 0
	$CollisionShape2D.rotation = 0
	spawning_dots = true
	show_damage_fx()

func show_damage_fx() -> void:
	var expl_pos: Vector2 = global_position
	var animated_sprite := AnimatedSprite2D.new()
	animated_sprite.position = expl_pos
	animated_sprite.scale = Vector2(.15, .15)
	animated_sprite.sprite_frames = explosion_effect_sprite_frames
	animated_sprite.animation_finished.connect(animated_sprite.queue_free)
	animated_sprite.play("explode")
	if not vulnerable:
		play_all_audio_multiselect([hurt_sfx, impact_sfx])
	else:
		play_audio(impact_sfx)
	node_spawn_host.add_child(animated_sprite)

func _on_prep_timer_timeout():
	is_preparing = false # The 2 seconds are up! Ready to attack!


func _on_animated_sprite_2d_animation_finished() -> void:
	shockdone = true
