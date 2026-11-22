extends CharacterBody2D
class_name Player

const free_grapple_distance: float = 105 
const free_grapple_animation_time: float = 0.100
const free_grapple_hook_movement_combination_time: float = 0.100
const free_grapple_hook_prefab_path: String = "uid://qjp2tm4naawh"

@onready var main: InGameOverlay = get_parent().get_node("InGameOverlay")
@onready var free_grapple_hook_prefab: PackedScene = load(free_grapple_hook_prefab_path)
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var collision: CollisionShape2D = $Collision
@onready var rope_line: Line2D = $Line2D # Make sure the name matches your node
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var floor_cast: RayCast2D = $Collision/Raycast
@onready var afterimage_manager: AfterimageManager = $AfterImageManager
@onready var perfect_bash_fx_manager: PerfectBashFxManager = $PerfectBashFxManager 
@onready var death_tween := get_tree().create_tween()

@export var death_time: float = 0.5
@export var camera: Camera
@export var max_health: int = 100
@export_group("Sounds")
@export var airdash_sfx: Array[AudioStream]
@export var screwdive_sfx: Array[AudioStream]
@export var skid_sfx: Array[AudioStream]
@export var grapple_sfx: Array[AudioStream]
@export var jump_sfx: Array[AudioStream]
@export var roll_sfx: Array[AudioStream]
@export var stomp_sfx: Array[AudioStream]
@export var boost_sfx: Array[AudioStream]
@export var death_sfx: Array[AudioStream]
@export var hit_sfx: Array[AudioStream]
@export var final_hit_sfx: Array[AudioStream]

var dying: bool = false
var is_taking_damage: bool = false
var hurt = false
var health: float = max_health:
	set(value):
		health = value
		if main.is_node_ready():
			main.log_health(health, max_health)
var has_initialized_health = false
var death_launch_velocity := Vector2.ZERO
var death_animation_last_t := 0
var death_animation_camera_origin: Vector2

var is_grapple_action_active: bool
var free_grapple_enabled: bool
var free_grapple_hook_deployed: bool
var can_deploy_free_grapple_hook: bool
var free_grapple_desired_direction: Vector2i
var free_grapple_position: Vector2
var free_grapple_animation_t: float
var free_grapple_hook: FreeGrappleHook 
var free_grapple_hook_offset: Vector2
var free_grapple_animation_last_hook_offset: Vector2
var free_grapple_hook_movement_base_direction: Vector2i
var free_grapple_hook_movement_combination_timeout: float

var motion := Vector2(0, 0)
var lastmotion := Vector2.ZERO
var rot := 0.0
var grounded := false
var slopeangle := 0.0
var slopefactor := 0.0
var exitgrapple = false
var springing: bool = false
var isattacking = false
var isskidding = false
var cangrapple = false
var canstomp = false
var stomp_enabled: bool = true
var canairdash = false
var canbash = true
var canperfectbash = false
var canspeedboost = false
var cantornadojump = false
var jumpcharge = 0
var canbounce = true
var isrolling = false
var isairdashing = false
var isstomping = false
var isbashing = false
var isperfectbashing = false
var isbouncing = false
var falloffwall = false
var control_lock = false
var stuck = false
var jumping = false
var snap_exception = false
var canjump = false
var jumpbuffered = false
var SLOPEMULT = 2
const AIRDRAG = 1.3
const MINSPD = 3
const JUMP_VELOCITY = 370
var GRAVITY = 850
var acc := 3
const dec := 15.0
const topspeed := 300.0

var is_grappling := false
var grapple_anchor_pos: Vector2 = Vector2.ZERO
var grapple_length := 0.0      # Radius (R)
var grapple_angle := 0.0       # Angle (Theta)
var grapple_ang_vel := 0.0     # Angular Velocity
const GRAPPLE_RANGE = 400.0 

func play_audio(streams: Array[AudioStream]):
	var choice = randi_range(0, len(streams) - 1)
	audio_stream_player.stream = streams[choice]
	audio_stream_player.play()

func play_all_audio(streams: Array[AudioStream]):
	var polystream := AudioStreamPolyphonic.new()
	audio_stream_player.stream = polystream
	audio_stream_player.play()
	var playback: AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	for stream in streams:
		playback.play_stream(stream)

# mutlistreams: Array[Array[AudioStream]]
func play_all_audio_multiselect(multistreams: Array[Array]):
	var streams: Array[AudioStream] = []
	for multistream: Array[AudioStream] in multistreams:
		var choice = randi_range(0, len(multistream) - 1)
		streams.append(multistream[choice])
	var polystream := AudioStreamPolyphonic.new()
	audio_stream_player.stream = polystream
	audio_stream_player.play()
	var playback: AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	for stream in streams:
		playback.play_stream(stream)

func stop_audio():
	var stream := audio_stream_player.stream
	if stream is AudioStreamWAV:
		if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			audio_stream_player.stop()
	elif stream is AudioStreamOggVorbis:
		if stream.loop:
			audio_stream_player.stop()
	elif stream is AudioStreamMP3:
		if stream.loop:
			audio_stream_player.stop()
	elif stream is AudioStreamPolyphonic:
		audio_stream_player.stop()
	if not audio_stream_player.playing:
		audio_stream_player.stream = null

func spawn_perfect_bash_fx() -> void:
	perfect_bash_fx_manager.spawn_particles()

func get_sprite_center() -> Vector2:
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var size := frame.get_size() * sprite.scale
	var position := sprite.position
	if sprite.centered:
		position -= size / 2.0
	var center := Rect2(position, size).get_center()
	return global_position

func is_area_contacting_ground(area_2d: Area2D) -> bool:
	for body in area_2d.get_overlapping_bodies():
		if body is StaticBody2D:
			return true
	return false

func _ready() -> void:
	afterimage_manager.target = sprite
	perfect_bash_fx_manager.player_sprite = sprite

func _physics_process(delta):
	
	if dying:
		return

	# 2. STATE MACHINE
	if is_grappling:
		# If grappling, we ignore ALL Maddie physics and run Pendulum physics
		physics_process_grapple(delta)
		
		# Check for release
		if Input.is_action_just_released("grapple"):
			stop_grapple()
	else:
		# If NOT grappling, we run your original Maddie Physics
		physics_process_normal(delta)

func attempt_grapple_start() -> bool:
	var all_anchors = get_tree().get_nodes_in_group("GrapplePoints")
	var target_anchor = null
	# We don't use a fixed distance number anymore. 
	# We strictly trust the Collision Circle of the anchor.
	
	for anchor_node in all_anchors:
		if anchor_node is Area2D:
			# STRICT CHECK: Only grapple if we are PHYSICALLY inside the Area2D shape
			if anchor_node.overlaps_body(self):
				target_anchor = anchor_node
				break # Found one, stop looking

	if target_anchor:
		if free_grapple_hook_deployed:
			disengage_free_grapple()
		is_grappling = true
		play_all_audio(grapple_sfx)
		grapple_anchor_pos = target_anchor.global_position
		
		# Set the rope length to the current distance. 
		grapple_length = global_position.distance_to(grapple_anchor_pos)
		
		grounded = false
		slopefactor = 0
		isairdashing = false
		isstomping = false
		canairdash = true
		canstomp = true
		rot = 0
		up_direction = Vector2.UP
		return true
	return false	

func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3)

func move_free_grapple_desired_direction(x: int, y: int):
	var new_x := free_grapple_hook_movement_base_direction.x
	new_x += x
	if new_x < -1:
		new_x = -1
	elif new_x > 1:
		new_x = 1
	var new_y := free_grapple_hook_movement_base_direction.y
	new_y += y
	if new_y < -1:
		new_y = -1
	elif new_y > 1:
		new_y = 1
	free_grapple_desired_direction = Vector2(new_x, new_y)
	free_grapple_hook_movement_base_direction = free_grapple_desired_direction
	free_grapple_hook_movement_combination_timeout = free_grapple_hook_movement_combination_time
	free_grapple_animation_t = 0

func engage_free_grapple_hook() -> void:
	var direction := free_grapple_desired_direction * free_grapple_distance
	if direction == Vector2.ZERO:
		return
	var target_position := direction + global_position
	var query_parameters := PhysicsRayQueryParameters2D.create(global_position, target_position)
	query_parameters.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query_parameters)
	if result:
		target_position = result["position"]
	free_grapple_hook_deployed = true
	free_grapple_hook = free_grapple_hook_prefab.instantiate()
	get_parent().add_child(free_grapple_hook)
	rope_line.visible = true
	rope_line.clear_points()
	free_grapple_hook_offset = target_position - position
	free_grapple_hook.rotation = free_grapple_hook_offset.angle()
	if result:
		free_grapple_hook.ground_normal_vector = result["normal"]
		free_grapple_hook.ground_normal_found = true
	can_deploy_free_grapple_hook = false
	
func engage_free_grapple(position: Vector2):
	free_grapple_position = position
	free_grapple_hook_deployed = false
	is_grappling = true
	grapple_length = global_position.distance_to(free_grapple_position)
	grounded = false
	slopefactor = 0
	isairdashing = false
	isstomping = false
	canairdash = true
	canstomp = true
	rot = 0
	up_direction = Vector2.UP
	free_grapple_enabled = true
	
func disengage_free_grapple(preserve_desired_direction: bool = false):
	exitgrapple = true
	is_grappling = false
	free_grapple_enabled = false
	free_grapple_hook_deployed = false
	if not preserve_desired_direction:
		free_grapple_desired_direction = Vector2i.ZERO
	free_grapple_hook_movement_base_direction = Vector2i.ZERO
	free_grapple_hook_movement_combination_timeout = 0
	free_grapple_animation_t = 0
	free_grapple_position = Vector2.ZERO
	rope_line.visible = false
	free_grapple_hook.queue_free()
	$Sprite.rotation = 0
	
func physics_process_grapple(delta: float):
	# 1. APPLY GRAVITY
	# We apply gravity first so it naturally accelerates/decelerates you based on the slope of the swing.
	motion.y += GRAVITY * delta

	# 2. CALCULATE ROPE GEOMETRY
	var anchor: Vector2
	# Dirty hack to re-use this code
	if free_grapple_enabled:
		anchor = free_grapple_position
	else:
		anchor = grapple_anchor_pos
	var vector_to_player = global_position - anchor 
	var current_dist = vector_to_player.length()
	
	# 3. CONSTRAINT SOLVER
	if current_dist >= grapple_length:
		# We are at the end of the rope (Taut)
		var rope_dir = vector_to_player.normalized()
		
		# --- A. HARD POSITION CORRECTION ---
		# Instead of using velocity to pull you back (which caused the super speed bug),
		# we simply force the position to stay on the circle edge.
		global_position = anchor + (rope_dir * grapple_length)
		
		# --- B. VELOCITY CONSTRAINT (NO FRICTION) ---
			
		# 1. Check if we are trying to move OUT of the circle
		var radial_speed = motion.dot(rope_dir)
		
		if radial_speed > 0:
			# We are moving outwards. We need to redirect this energy.
				
			# Capture the speed we had BEFORE we hit the limit (Conservation of Energy)
			var speed_preservation = motion.length()
			
			# Remove the outward component (Project onto Tangent)
			motion -= rope_dir * radial_speed
			
			# RE-APPLY SPEED
			# We take the new direction (perfect tangent), but force the speed 
			# to match what we had before. This eliminates the "Friction" you felt.
			if motion.length() > 0:
				motion = motion.normalized() * speed_preservation

	# 4. MOVE
	# We rely on move_and_slide to handle walls/floors, but our position 
	# is already strictly constrained to the rope circle above.
	velocity = motion
	move_and_slide()
	
	# 5. WALL COLLISION HANDLING
	# If we hit a wall while swinging, we need to update 'motion' or we'll stick.
	if $Collision/WallCast.is_colliding() and is_on_wall():
		motion.x = 0
	if $Collision/Raycast.is_colliding and is_on_floor():
		motion.y = 0

	# 6. Rotation reset to default (zero)
	$Collision.rotation = 0

	# 7. VISUALS
	rope_line.visible = true
	rope_line.clear_points()
	var sprite_center := get_sprite_center()
	rope_line.add_point(Vector2.ZERO) 
	rope_line.add_point(rope_line.to_local(anchor))
	
	#Grapple animation
	$Sprite.play("jump")
	$Sprite.speed_scale = 4

	$Sprite.offset.y = 1
	$Sprite.position.y = -15

	$Sprite.flip_h = false
	$Sprite.rotation = lerp_angle($Sprite.rotation, motion.angle(), 1)
	$Sprite.play("airdash")
	$Sprite.speed_scale = 1

func stop_grapple():
	exitgrapple = true
	is_grappling = false
	free_grapple_enabled = false
	free_grapple_hook_deployed = false
	free_grapple_desired_direction = Vector2i.ZERO
	free_grapple_animation_t = 0
	free_grapple_position = Vector2.ZERO
	rope_line.visible = false
	$Sprite.rotation = 0
	
	$Sprite.offset.y = -270.04
	$Sprite.position.y = 1

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
			var n = col.get_normal()
			
			if is_on_wall():
			# A perfectly flat wall has a Y normal of 0.
			# A perfectly flat ceiling has an X normal of 0.
			# We ONLY want to attach if both X and Y are greater than 0 (meaning it's angled).
				if abs(n.x) > 0.01 and abs(n.y) > 0.01:
					is_touching_surface = true
					surface_normal = n
					break
			elif is_on_ceiling():
				if abs(n.x) > 0.7 and motion.y < 75:
					is_touching_surface = true
					surface_normal = n
					break
					
					
	# --- 2. CALCULATE SLOPE DATA ---
	if is_touching_surface and !springing:
		slopeangle = surface_normal.angle() + (PI/2)
		slopefactor = surface_normal.x
	else:
		slopefactor = 0

	# --- 3. ROTATION VISUALS ---
	$Collision.rotation = rot
	$Sprite.rotation = lerp_angle($Sprite.rotation, rot, 0.25)

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
		var base_ray_length = 4.0 # (Keep your custom value here)
		
		if grounded:
			if jumping or snap_exception:
				grounded = false
				motion = get_real_velocity() 
				rot = 0
				up_direction = Vector2(0, -1)
				# 1. MID-AIR ENFORCEMENT (Jump): Reset raycast instantly
				$Collision/Raycast.target_position = Vector2(0, base_ray_length)
			else:
				var should_detach = false
				
				# 2. DYNAMICALLY EXTEND (Only while grounded)
				# We use min() to put a hard limit on the extension so it doesn't grow infinitely at high speeds
				var speed_reach = abs(motion.x) * delta * 18.0 
				
				$Collision/Raycast.target_position = Vector2(0, base_ray_length + speed_reach)
				$Collision/Raycast.force_raycast_update() 
				
				# 3. CHECK COLLISION AND ANGLE
				if not $Collision/Raycast.is_colliding():
					should_detach = true
				else:
					var hit_point = $Collision/Raycast.get_collision_point()
					var distance_to_floor = global_position.distance_to(hit_point)
					
					# CLIFF DETECTOR: If the floor is found, but it's too far down, it's a ledge drop, not a slope!
					# (You can tweak the '20.0' if you find yourself falling off very steep slopes)
					if distance_to_floor > (base_ray_length + 20.0):
						should_detach = true
					else:
						var ray_normal = $Collision/Raycast.get_collision_normal()
						var next_slopeangle = ray_normal.angle() + (PI/2)
						var angle_diff = abs(angle_difference(rot, next_slopeangle))
						
						if angle_diff >= deg_to_rad(50):
							should_detach = true
						else:
							# SMOOTH ATTACHMENT FIX
							up_direction = ray_normal
							rot = next_slopeangle
							
							var temp_vel = velocity
							velocity = Vector2(0, (distance_to_floor / delta) * 1.5).rotated(rot) 
							move_and_slide() 
							velocity = temp_vel
							
				# 4. APPLY DETACHMENT
				if should_detach:
					grounded = false
					motion = get_real_velocity()
					rot = 0
					up_direction = Vector2(0, -1)
					
				# 5. RESET RAYCAST
				$Collision/Raycast.target_position = Vector2(0, base_ray_length)

		else:
			# --- MID-AIR ENFORCEMENT (Falling) ---
			# If the player is already mid-air (grounded is false), guarantee the raycast is locked to normal.
			$Collision/Raycast.target_position = Vector2(0, base_ray_length)

# Gravity
	if not is_on_floor() and rot == 0 or springing:
		motion.y += GRAVITY * delta
		# The basic Gravity procedure.
		# We only trigger this if you're in the air. Otherwise, your vertical motion- 
		# -would try to increase infinitely while you're on the ground.
		if springing and motion.y >= 0:
			springing = false
	else:
		if abs(slopefactor) == 1: # If running up a perfectly vertical wall...
			motion.y = 0
			# This makes sure you don't get any unwanted horizontal air speed when- 
			# -riding a perfectly U-shaped crevice. (Most of the time, at least.)
			# Without this, the motion addition below would cause you to drift off to-
			# -the side after launching yourself upwards.
		else:
			motion.y = 50
			# This tries to help you stick to the ground, though it's not very-
			# -effective at high speeds.

	if is_on_floor():
		exitgrapple = false
		
	if Input.is_action_just_pressed("jump"):
		jumpbuffered = true
		$JumpBufferTimer.start()
		# When the Jump button is pressed, start buffering the jump.
		# In the same breath, let's start a timer. Once that timer runs out,
		# the jump will stop being buffered.
		
	if not grounded and canjump: # If you're not on the ground, but are still able to jump...
		if $CoyoteTimer.is_stopped():
			$CoyoteTimer.start()
			# Start the Coyote timer.
			## We must only start it if it's stopped.
			## Otherwise, it would just constantly restart itself before it even finishes.
	else:
		$CoyoteTimer.stop()
		# If you're on the ground, or are already not able to jump, then there's no reason-
		# -for us to start the timer.

	if jumpbuffered and canjump: # If your jump input is detected and you're currently able to jump...
		motion.y = -JUMP_VELOCITY
		jumping = true
		play_audio(jump_sfx)
		# Jump.
		
		canjump = false
		canbash = false
		# Then revoke your ability to jump. Don't worry, this will get reactivated once you land.
		## Without this part, you'd be able to fly up infinitely.
		
		if abs(rot) > 1: # If you're sideways or upside-down (on a wall or cieling)...
			position += Vector2(0, -(14)).rotated(rot)
			# Shift your position a bit away from the floor.
			## Because of the type of collision we're using,
			## getting stuck in a wall or ceiling is a big risk the player has.
			## This tries to prevent that from happening.
		
		$JumpBufferTimer.stop()
		jumpbuffered = false
		# Once all that's done, we stop the timer from running out-
		# -so that we can deactivate the buffer manually.
		# We are no longer detecting that Jump input.

	if motion.y >= 0 and grounded: # If you're DEFINITELY on the ground...
		jumping = false
		snap_exception = false
		canjump = true
		isbouncing = false
		hurt = false
		# Let the script know you're not jumping anymore, and return your ability to jump.

	if not springing:
		if jumping and motion.y < -JUMP_VELOCITY / 1.625: # If your jumping motion goes beyond a certain point...
			if not Input.is_action_pressed("jump") and not Input.is_action_pressed("action") and not exitgrapple: # ...but you're NOT pressing the jump button anymore...
				motion.y = -JUMP_VELOCITY / 2.2


#POOPY ELEMENTAL SHIELD ABILITIES 

	if Input.is_action_just_pressed("boost") and canspeedboost:
		motion.x = 690 * sign($Collision/WallCast.target_position.x)
		play_audio(boost_sfx)
		camera.screen_shake_for(.25)
		canspeedboost = false
		
	if cantornadojump and grounded:
		if Input.is_action_pressed("boost"):
			jumpcharge += 5
			jumpcharge = clamp(jumpcharge, 200, 1200)

		elif Input.is_action_just_released("boost"):
			snap_exception = true
			rot = 0 #no slope jump bc that would be too OP
			motion.y = -1 * jumpcharge #remember: the y axis of godot is inverted.
			
			play_audio(boost_sfx)
			camera.screen_shake_for(.25)
			
			cantornadojump = false
			jumpcharge = 0
			
	if canbounce and Input.is_action_pressed("boost"):
		# If we were airborne and just touched a valid surface...
			if get_slide_collision_count() > 0:
				var bounce_surface_normal = get_slide_collision(0).get_normal()
				
				if lastmotion.length() > 450:
					snap_exception = true
					grounded = false
					
					motion = lastmotion.bounce(bounce_surface_normal)
					
					isbouncing = true
					rot = 0
					up_direction = Vector2.UP
			
	# Get player's direction axis
	var direction: float = Input.get_axis("left", "right") # Emits "-1" if holding left, and "1" if holding right.
	if Input.is_action_pressed("enemyfreeze"):
		# Lock movement while grid-moving
		direction = 0
	# Prevent controller from allowing unlimited speed boost bugs
	if direction < 0:
		direction = -1
	elif direction > 0:
		direction = 1

	if jumping or isrolling or isairdashing or isstomping or isbashing:
		isattacking = true
	else:
		isattacking = false
	
	if not is_on_floor():
		if abs(motion.x) > topspeed:
			motion.x = move_toward(motion.x, topspeed, AIRDRAG)
			
	if is_on_floor():
		isairdashing = false
		isstomping = false
		canairdash = true
		canstomp = true
		
	if abs(motion.x) < 20:
		isairdashing = false
	
	if not grounded:
		if Input.is_action_pressed("action") and Input.is_action_pressed("down") and canstomp and stomp_enabled:
			if motion.y < 0:
				motion.y = 450

				canstomp = false
				isstomping = true
				play_all_audio_multiselect([stomp_sfx, screwdive_sfx])
				isairdashing = false
			elif motion.y >= 0:
				motion.y += 450

				canstomp = false
				isstomping = true
				play_all_audio_multiselect([stomp_sfx, screwdive_sfx])
				isairdashing = false
			stomp_enabled = false
		elif Input.is_action_just_pressed("action") and canairdash and abs(motion.x) >= 20:
			motion.x += abs(motion.x) * 0.15 * Input.get_axis("left", "right")
			canairdash = false
			isairdashing = true
			play_all_audio_multiselect([airdash_sfx, screwdive_sfx])
			isstomping = false
	elif grounded:
		if Input.is_action_just_pressed("action") and not control_lock:
			if (canbash or canperfectbash):
				var bashingspeed = 375
				var bashingfactor
				
				isbashing = true
				
				if canperfectbash:
					canperfectbash = false
					isperfectbashing = true
					bashingfactor = 1.7
				else:
					bashingfactor = 1

				if (direction != 0):
					motion.x = bashingspeed * direction * bashingfactor
				else:
					motion.x = bashingspeed * sign($Collision/WallCast.target_position.x) * bashingfactor
				
				if (not isperfectbashing): #if you just bashed instead of perfect bashing
					$NormalBashing_Duration.start()
				
			elif isbashing and (not canperfectbash) and (not isperfectbashing):
				isbashing = false
				#motion.x = 150 * sign(motion.x)
				$Final_Bashing.stop() #If the timer doesn't reset, the timeout function makes the bashing state false even after the player exits bashing due to reasons other than the time running out
				$NormalBashing_Duration.stop()
				#when you miss the timing of perfect bashing, you get a penalty.
	
	if (not grounded or abs(motion.x) < 30 or isskidding or isrolling):
		$Final_Bashing.stop()  #If the timer doesn't reset, the timeout function makes the bashing state false even after the player exits bashing due to reasons other than the time running out
		$NormalBashing_Duration.stop()
		isbashing = false
		isperfectbashing = false
	
	#You can't bash while you're already bashing.
	if isbashing:
		canbash = false
	else:
		canbash = true
				
	
	if not Input.is_action_pressed("action"):
		stomp_enabled = true
	
	#This is for the speed display in the UI
	main.display_speed(motion.x, motion.y)
	
	if abs(motion.x) != 0:
		# If moving right (1), point right. If moving left (-1), point left.
		# Multiply by whatever distance your raycast needs to reach (e.g., 20 pixels)
		$Collision/WallCast.target_position.x = 7.0 * sign(motion.x)
		
		#braking control seen in classic sonic games
	if direction == -(sign(motion.x)) and (abs(motion.x) >= (topspeed/1.5)) and is_on_floor():
		if not isskidding and not is_taking_damage:
			play_audio(skid_sfx)
		isskidding = true
	if abs(motion.x) == 0 or (not is_on_floor()) or direction != -(sign(motion.x)):
		isskidding = false
	if isskidding:
		if direction == -(sign(motion.x)):
			motion.x -= dec * sign(motion.x) * 1.3
			
	if not isbashing:#This has it so that you can't influence the direction when you're bashing.
						
		if direction and not control_lock and not isrolling and !springing: # If holding left or right, and not slipping down a slope...
			if abs(motion.x) < 25:
				motion.x += acc * 3 * direction
			if is_on_floor(): # If touching the floor...	
				if direction == sign(motion.x): # If you're holding in the direction you're moving...
					if abs(motion.x) <= topspeed: # If you're not over your Top Speed...
						motion.x += acc * direction
						# Accelerate in the direction you're holding.
						
				else: # If you're trying to turn around...
					if abs(slopefactor) < 0.4: # If you're standing on flat or slightly slanted ground...
						if not isskidding:
							motion.x += dec * direction * 2
							
						# Very quickly Deccelerate to a stop.
						else: # If you're standing on a far too steep slope...
							motion.x += acc * direction
						# Turn at normal speed.
						## Logically, it would be pretty hard to slow down when running down a hill.
					
					
			else: # If mid-air...
				
				if direction == sign(motion.x): # If you're holding in the direction you're moving...
					if abs(motion.x) <= topspeed: # If you're not over your Top Speed...
						motion.x += (acc * 1.2) * direction
						# Accelerate (a bit faster) in the direction you're holding.
						
				else: # If you're trying to turn around...
					if abs(motion.x) <= topspeed - 50:
						motion.x += (acc * 2.7) * direction
					elif abs(motion.x) > topspeed - 50:
						motion.x += (acc * 5.5) * direction
					# Deccellerate at the same speed.
				
				# Note: Due to logic, you can't quickly turn around mid-air.
				
		else: # If not pressing anything...
			if is_on_floor() and abs(slopefactor) < 0.25 or isrolling: # If you're on flat, or near-flat ground...
				motion.x = move_toward(motion.x, 0, acc - 1)
				# Slow to a stop.
				## We shouldn't be able to stand perfectly still on a steep slope, right? Right.
			elif is_on_floor() and abs(slopefactor) < 0.25:
				motion.x = move_toward(motion.x, 0, acc)
			elif not is_on_floor() and (abs(motion.x) <= topspeed):
				motion.x = move_toward(motion.x,0, acc - 1)
	velocity = Vector2(motion.x, motion.y).rotated(rot)

#rolling
	if Input.is_action_pressed("down") and is_on_floor() and abs(motion.x) > 25:
		if not isrolling:
			play_audio(roll_sfx)
		isrolling = true
	if Input.is_action_just_released("down") or not is_on_floor():# or abs(motion.x) <= 25:
		isrolling = false
		
# Slopes
	if isrolling:
		SLOPEMULT = 5
	else:
		SLOPEMULT = 2
		
	if is_on_floor() and not stuck and not isbashing: #when you're bashing, the slope doesn't affect your speed.
		motion.x += (acc * SLOPEMULT) * slopefactor
		# When you're moving down a slope, add more acceleration.
		# When you're moving up a slope, slow the player down.
		## This is what gives Momentum.
		## Without this, running up walls would be too unnaturally easy.
	
	if grounded and abs(slopefactor) >= 0.5 and abs(motion.x) < 10: # 
		control_lock = true
		$ControlLockTimer.start()
		# If you slow down too much on a steep slope, briefly remove the ability to move left and right.
		## This makes the player slip down the slope
	
	if grounded and abs(slopeangle) > 1.5: # If you're on a wall...
		if abs(motion.x) < 80: # ...and you're moving too slow...
			falloffwall = true
			position += Vector2(0, -(14)).rotated(rot)
			canjump = false
			# Detatch from the wall.
			
			grounded = false
			motion = get_real_velocity()
			rot = 0
			up_direction = Vector2(0, -1)
					
			#RESET RAYCAST
			$Collision/Raycast.target_position = Vector2(0, 4)
			
			control_lock = true
			$ControlLockTimer.start()
	else:
		falloffwall = false

# Stoppers
	if is_on_ceiling() and not grounded: # If you bonk your head on the ceiling...
		if motion.y < 0: # If you're moving up...
			motion.y = 100
			# Get sent right back down.

	if is_on_wall() and $Collision/WallCast.is_colliding() and not isbouncing:
		# If you bump into a wall...
		if not grounded:
			motion.x = 0
		elif grounded:
			if abs(slopefactor) == 0 or abs(slopefactor) == 1:
				motion.x = 0
		# Stop moving.

	animate()

	lastmotion = motion
	move_and_slide()

func _process(delta: float) -> void:
	if health <= 0 and !dying:
		die()
	if !has_initialized_health and main.is_node_ready():
		has_initialized_health = true
		main.log_health(health, max_health)
	if Input.is_action_just_pressed("enemyfreeze"):
		var enemies = get_tree().get_nodes_in_group("Enemy")
		var choice: Enemy = null
		var min_dist = INF
		for enemy in enemies:
			var dist = enemy.global_position.distance_to(global_position)
			if dist < min_dist:
				choice = enemy
				min_dist = dist
		if choice and !choice.isfrozen:
			choice.engage_freeze()
	if is_grapple_action_active:
		if not is_grappling:
			var success := attempt_grapple_start()
			if not success and can_deploy_free_grapple_hook:
				if free_grapple_hook_deployed:
					disengage_free_grapple(true)
				engage_free_grapple_hook()
	if free_grapple_hook_deployed:
		if grounded:
			disengage_free_grapple()
		else:	
			var offset := free_grapple_desired_direction * free_grapple_distance
			var target_position: Vector2 = position + lerp(free_grapple_animation_last_hook_offset, offset, ease_out_cubic(free_grapple_animation_t))
			free_grapple_hook.position = target_position
			var sprite_center = get_sprite_center()
			rope_line.clear_points()
			rope_line.add_point(rope_line.to_local(sprite_center)) 
			rope_line.add_point(rope_line.to_local(target_position))
			if free_grapple_animation_t < 1:
				free_grapple_animation_t += delta / free_grapple_animation_time
			else:
				free_grapple_animation_last_hook_offset = free_grapple_hook_offset
			var query_parameters := PhysicsRayQueryParameters2D.create(global_position, free_grapple_hook.global_position)
			query_parameters.exclude = [get_rid()]
			var result := get_world_2d().direct_space_state.intersect_ray(query_parameters)
			if result and result["collider"] is StaticBody2D:
				var result_position: Vector2 = result["position"]
				free_grapple_hook.global_position = result_position
				free_grapple_hook.deploy()
				engage_free_grapple(result_position)
			if free_grapple_hook_movement_combination_timeout > 0:
				free_grapple_hook_movement_combination_timeout -= delta
			else:
				free_grapple_hook_movement_base_direction = Vector2i.ZERO
	if isairdashing or isstomping:
		afterimage_manager.enabled = true
	else:
		afterimage_manager.enabled = false

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()
	else:
		is_taking_damage = true
		play_audio(hit_sfx)
		await audio_stream_player.finished
		is_taking_damage = false

func bounce(strength: float) -> void:
	var dir = Vector2(-.5,-.5)
	if $Sprite.flip_h:
		dir.x = -dir.x
	var force = dir * strength
	motion = force
	springing = true
	snap_exception = true
	hurt = true

var idle := true
var idleset := false

func animate():
	var direction = Input.get_axis("left", "right")
	
	if (jumping or isairdashing):
		$Sprite.offset.y = 1
		$Sprite.position.y = -15
	else:
		$Sprite.offset.y = -270.04
		$Sprite.position.y = 1
	
	#This one's for the sprite flippin' logic
	if (isskidding):
		if sign(motion.x) > 0:
			$Sprite.flip_h = false
		elif sign(motion.x) < 0:
			$Sprite.flip_h = true
	elif (not jumping or not isairdashing):	
		if direction < 0 and not isskidding:
			$Sprite.flip_h = true
		elif direction > 0 and not isskidding:
			$Sprite.flip_h = false
	
	if isrolling:
		$Sprite.play("slide")
		
		var animspeed = abs(motion.x) / 80
		animspeed = clamp(animspeed, 1.5, 8)
			
		$Sprite.speed_scale = animspeed
		
	elif grounded:
		
		if (isbashing):
			$Sprite.speed_scale = 1
			if (isperfectbashing):
				$Sprite.play("perfectbashing")
			else:
				$Sprite.play("bashing")
		
		elif isskidding:
			$Sprite.play("skid")
		
		elif abs(motion.x) < 1: # If you're standing still, or at least EXTREMELY CLOSE to standing still...
			$Sprite.speed_scale = 1
			stop_audio()
			# Reset the Speed Scale.
			
		elif abs(motion.x) < topspeed - 10: # If you're moving, but not at your Top Speed yet...
			$Sprite.play("walk")
			$Sprite.speed_scale = 0.5 + (abs(motion.x) / 350)
			stop_audio()
			# Play Walking Animation at half speed, quickening it as you move faster and faster.
			
		elif abs(motion.x) >= topspeed: # If you've reached, or are at least close enough to your Top Speed...
			$Sprite.play("run")
			$Sprite.speed_scale = clamp(abs(motion.x)/90, 1.5, 8)
			stop_audio()
			# Play Running Animation, quickening it even further if you escalate past your Top Speed.
			
	elif not grounded:
		
		if hurt:
			$Sprite.play("hurt")
				
		elif isstomping:

			var stomprot = -1 * motion.x / 1000
		
			stomprot = clamp(stomprot, -PI/4.5, PI/4.5)
		
			$Sprite.rotation = lerp_angle($Sprite.rotation, stomprot, 1)
				
			#Actual animation
			$Sprite.play("stomp")
			$Sprite.speed_scale = clamp(motion.y/250, 1, 3)
	
		elif isairdashing or jumping:
			$Sprite.flip_h = false
			$Sprite.speed_scale = 1
			if (jumping and abs(motion.x) < 100):
				$Sprite.rotation = lerp_angle($Sprite.rotation, 0, 1)
				$Sprite.play("jump")
			else:
				$Sprite.rotation = lerp_angle($Sprite.rotation, motion.angle(), 1)
				$Sprite.play("airdash")
	
	# Idle animation
	
	if grounded and abs(motion.x) < 1:
		idle = true
	else:
		idle = false
	
	if idle:
		if idleset:
			stop_audio()
			$Sprite.play("idle")
			idleset = false

		if $IdleTimer.is_stopped():
			$IdleTimer.start()
	else:
		idleset = true
		$IdleTimer.stop()

# Timer signals

func _on_control_lock_timer_timeout():
	control_lock = false
	# After a brief moment, your ability to move left and right is restored.

func _on_jump_buffer_timer_timeout():
	jumpbuffered = false
	# If you pressed jump but aren't close enough to the ground, it stops buffering your jump.

func _on_coyote_timer_timeout():
	canjump = false
	# If you've been in the air for too long, your ability to jump is revoked.
	
func _on_normal_bashing_duration_timeout():
	if isbashing: #If you get penalized for missing the timing of perfect bashing, you can't perfect bash
		canperfectbash = true
		spawn_perfect_bash_fx() #visual indicator of the perfect timing
		play_audio(boost_sfx)
		$PerfectBashing_Timing.start()
		$Final_Bashing.start()
	

func _on_perfect_bashing_timing_timeout():
	canperfectbash = false

func _on_final_bashing_timeout():
	isbashing = false
	isperfectbashing = false

func die():
	if death_tween.is_running():
		death_tween.kill()
		death_tween = get_tree().create_tween()
	death_animation_camera_origin = camera.global_position
	motion = Vector2.ZERO
	dying = true
	var sprite: AnimatedSprite2D = $Sprite
	sprite.play("stare")
	death_tween.set_ease(Tween.EASE_IN)
	death_tween.set_trans(Tween.TRANS_CUBIC)
	death_tween.tween_callback(func():
		play_audio(final_hit_sfx))
	death_tween.tween_interval(1)
	death_tween.tween_callback(func():
		play_audio(death_sfx)
		camera.frozen = true)
	death_tween.tween_method(death_launch, 0., 1., 2)
	var end_angle: int = -90
	if $Sprite.flip_h:
		end_angle = 90
	death_tween.parallel().tween_property(self, "global_rotation_degrees", end_angle, .25)
	death_tween.parallel().tween_await(audio_stream_player.finished)
	death_tween.parallel().tween_method(screen_shake, 5, 5, .25)
	death_tween.tween_callback(restart)

func screen_shake(intensity: float):
	camera.global_position = death_animation_camera_origin + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func death_launch(t: float):
	var delta := t - death_animation_last_t
	if t < 0.03:
		var h_comp: Vector2 = Vector2.LEFT
		if $Sprite.flip_h:
			h_comp = Vector2.RIGHT
		death_launch_velocity += (Vector2.UP * 1.25 + h_comp) * 1000
	global_position += death_launch_velocity * delta
	death_launch_velocity.y += 1700000 * delta

func restart():
	death_tween.kill()
	Global.begin_level_crossfade(Global.current_level)

func _input(event: InputEvent) -> void:
	var grapple_pressed := event.is_action_pressed("grapple")
	if grapple_pressed:
		is_grapple_action_active = true
	elif event.is_action_released("grapple"):
		if free_grapple_hook_deployed or free_grapple_enabled:
			disengage_free_grapple()
		is_grapple_action_active = false 
		free_grapple_desired_direction = Vector2.ZERO
		free_grapple_animation_last_hook_offset = Vector2.ZERO
	if is_grapple_action_active and not free_grapple_enabled:
		var old_desired_direction := free_grapple_desired_direction
		var direction := Vector2i.ZERO
		if event.is_action_pressed("grid_up", false) or (grapple_pressed and Input.is_action_pressed("grid_up")):
			direction.y -= 1
		if event.is_action_pressed("grid_down", false) or (grapple_pressed and Input.is_action_pressed("grid_down")):
			direction.y += 1
		if event.is_action_pressed("grid_left", false) or (grapple_pressed and Input.is_action_pressed("grid_left")):
			direction.x -= 1
		if event.is_action_pressed("grid_right", false) or (grapple_pressed and Input.is_action_pressed("grid_right")):
			direction.x += 1
		if direction != Vector2i.ZERO:
			move_free_grapple_desired_direction(direction.x, direction.y)
		if old_desired_direction != free_grapple_desired_direction:
			can_deploy_free_grapple_hook = true
