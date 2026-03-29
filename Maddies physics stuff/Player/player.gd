extends CharacterBody2D
class_name Player

@onready var gamemanager: Node2D = %gamemanager
@onready var collision: CollisionShape2D = $Collision
@onready var camera_2d: Camera2D = $Camera2D
@onready var anchor: Area2D = $"../anchor"
@onready var rope_line: Line2D = $Line2D # Make sure the name matches your node

### ### Maddie's Ultra-Simple Sonic Physics!! ### ###
## The absolute bare minimum needed to make a Sonic fangame.

## Right now, it's just the 360 degree movement and slope physics, nothing else.

## I've written tons of helpful comments in the hopes that you'll understand how this code works.
## Then, if you do, I encourage you to try and add stuff like a spindash or a boost, if you want.


## I've also set bookmarks for each segment of the script.

## To access the bookmarks, look above that text field at the top left that says "Filter Scripts"-
## -and click "Go To". Then, click "Bookmarks". Now you'll hopefully be able to-
## -easily navigate this script.


## If you end up using this for a game, credit is absolutely not required, but would be appreciated.


## If the comments get annoying, find the script labelled "player (no comments)"-
## -and swap this script out with that one.




## Variables go at the top. Let's start with the most important ones.

var motion := Vector2(0, 0)
# Motion, the magical variable. Consider it a pseudo-Velocity.
## Motion and Velocity are used in conjunction with each other to simulate the 360 degree movement-
## -found in Classic Sonic games, only with much more theoretical effectiveness.
## Check underneath the "Movement" segment of the script for a full explanation.

var rot := 0.0
# Rotation.
## This helps your Sprite and Collision rotate.

var grounded := false
# The state that tracks if you've left the floor.
## Walking on a wall or a ceiling also counts as being grounded.

var slopeangle := 0.0
# The exact angle (in Radians) of the floor you're standing on.
## This number will be positive if the slope rises to the left, and negative if it rises to the right.
# Why Radians?
# Because Degrees calculations are finicky in this engine. Radians are far more accurate.

var slopefactor := 0.0
# The steepness of the slope you're standing on.
## Straight floors and cielings will emit "0". Perfectly vertical walls will emit "1".
## This number will be positive if the slope rises to the left, and negative if it rises to the right.

var exitgrapple = false

var isskidding = false

var cangrapple = false

var canstomp = false

var canairdash = false

var isrolling = false

## Fixes for problems involving walls and steep slopes.

var falloffwall = false
# This makes sure you can't permanently stick to the wall.
## See the "Slope" section of the script for more info.

var control_lock = false
# This briefly removes your ability to move if you're trying to walk up a slope that's far too steep.
## See the "Slope" section of the script for more info.

var stuck = false
# This one activates in a very specific situation involving a steep downward slope and a wall.
## See the very bottom of this script for more info.




## Jump variables. These help us make a Jump mechanic that feels really good.

var jumping = false
# Activates if you've successfully left the ground by Jumping.
## This one is necessary for our Variable Jump Height.

var canjump = false
# Whether or not you're able to jump. When deactivated, your jump button will become useless.
## This one is necessary for our Coyote Timer.

var jumpbuffered = false
# Briefly activates every time you press the Jump button.
## This one variable is necessary for our Jump Buffer.




## The Player's stats.

var SLOPEMULT = 2

const AIRDRAG = 1.3

const MINSPD = 3

const JUMP_VELOCITY = 370
# Jump height. Default: 350.0

var GRAVITY = 850
# Gravity force. Default: 600

var acc := 3
# Acceleration. Default: 2
# This is what moves you forward.

const dec := 15.0
# Deccelleration. Default: 30.0
## This is only used when you try to turn around.

const topspeed := 300.0
# Top Speed. Default: 300.0
## You won't be able to Accelerate past this point without some Momentum.

## Note: If you'd like to change the player's stats mid-game, make them variables instead.
## You can do this by changing the word "const" to "var".

### ### GRAPPLING HOOK ADDITIONS ### ###
var is_grappling := false
var grapple_anchor_pos := Vector2.ZERO # Where are we hanging from?
var grapple_length := 0.0      # Radius (R)
var grapple_angle := 0.0       # Angle (Theta)
var grapple_ang_vel := 0.0     # Angular Velocity
# Max distance to grab an anchor
const GRAPPLE_RANGE = 400.0 
### ### ### ### ### ### ### ### ### ###


func _physics_process(delta):
	
	# 1. CHECK FOR GRAPPLE START
	# If we press the button and aren't already grappling...
	if Input.is_action_pressed("grapple") and not is_grappling: 
		attempt_grapple_start()

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


### ### NEW GRAPPLE FUNCTIONS ### ###
func attempt_grapple_start():
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
		is_grappling = true
		grapple_anchor_pos = target_anchor.global_position
		
		# Set the rope length to the current distance. 
		grapple_length = global_position.distance_to(grapple_anchor_pos)
		
		# Reset Maddie's physics states
		grounded = false
		slopefactor = 0
		canairdash = true
		canstomp = true
		rot = 0

func physics_process_grapple(delta: float):
	# 1. APPLY GRAVITY
	# We apply gravity first so it naturally accelerates/decelerates you based on the slope of the swing.
	motion.y += GRAVITY * delta

	# 2. CALCULATE ROPE GEOMETRY
	var vector_to_player = global_position - grapple_anchor_pos
	var current_dist = vector_to_player.length()
	
	# 3. CONSTRAINT SOLVER
	if current_dist >= grapple_length:
		# We are at the end of the rope (Taut)
		var rope_dir = vector_to_player.normalized()
		
		# --- A. HARD POSITION CORRECTION ---
		# Instead of using velocity to pull you back (which caused the super speed bug),
		# we simply force the position to stay on the circle edge.
		global_position = grapple_anchor_pos + (rope_dir * grapple_length)
		
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
	if is_on_wall() or is_on_floor():
		motion = get_real_velocity()
		# Optional: If you hit a floor, maybe end the grapple?
		# stop_grapple() 

	# 6. VISUALS
	rope_line.visible = true
	rope_line.clear_points()
	rope_line.add_point(Vector2.ZERO) 
	rope_line.add_point(rope_line.to_local(grapple_anchor_pos))
	
	# Rotate sprite to face velocity
	#if motion.length() > 10:
		#var look_angle = motion.angle()
		#$Sprite.rotation = rotate_toward($Sprite.rotation, look_angle, 0.15)

func stop_grapple():
	exitgrapple = true
	is_grappling = false
	
	# Since we used Vector2 physics the whole time, 
	# 'motion' is already correct! We don't need to do any math conversion.
	
	# Just a small boost or cap if you want, otherwise leave it raw.
	
	rope_line.visible = false
	$Sprite.rotation = 0

### ### WRAPPER FOR YOUR ORIGINAL CODE ### ###

## Alright, let's get started.

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
			
			# A perfectly flat wall has a Y normal of 0.
			# A perfectly flat ceiling has an X normal of 0.
			# We ONLY want to attach if both X and Y are greater than 0 (meaning it's angled).
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
		if not $Collision/Raycast.is_colliding() and grounded:
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
	



# Jump

# You'd think a Jumping mechanic would be simple, right? 
# Just add -JUMP_VELOCITY when you press the Jump button while on the floor, and you're done.
# That would make sense, but in reality, it's just not that simple.
# Think of it this way: While the game has frame-perfect reaction time for every little thing, the-
# -PLAYER does not.
# For example, you might walk off a cliff for a single frame and THEN press the jump button.
# In that situation, the game will NOT be forgiving.
# It will only see that you're not on the ground, and will ignore the jump input accordingly,
# -causing you to fall down embarrasingly.

# To avoid this, let's make a forgiving Jump mechanic.


## First, we make sure every jump input gets buffered.
# This will let us detect a single jump input for several frames instead of just one.

# The intention for this is to make it so that if you press jump slightly before hitting the ground, 
# it'll execute the jump the moment you land.

	if is_on_floor():
		exitgrapple = false
		
	if Input.is_action_just_pressed("jump"):
		jumpbuffered = true
		$JumpBufferTimer.start()
		# When the Jump button is pressed, start buffering the jump.
		# In the same breath, let's start a timer. Once that timer runs out,
		# the jump will stop being buffered.
		
		## To see exactly what happens when this timer runs out, check near the very bottom of the script.

## Now for the Coyote Timer.

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

## Alright! Now let's actually execute the jump.

	if jumpbuffered and canjump: # If your jump input is detected and you're currently able to jump...
		motion.y = -JUMP_VELOCITY
		jumping = true
		# Jump.
		
		canjump = false
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
		canjump = true
		# Let the script know you're not jumping anymore, and return your ability to jump.


	if jumping and motion.y < -JUMP_VELOCITY / 1.625: # If your jumping motion goes beyond a certain point...
		if not Input.is_action_pressed("jump") and not Input.is_action_pressed("action") and not exitgrapple: # ...but you're NOT pressing the jump button anymore...
			motion.y = -JUMP_VELOCITY / 2.2
			# Set your vertical motion to that exact point.
			## Simply put, this lets you do high and low jumps depending on- 
			## -how long you press the button.




 #(Debug) Speed Boost
	#if Input.is_action_just_pressed("boost"):
	#	motion.x += 500 * Input.get_axis("left", "right")
		
#	var actionlist = ["action", "grapple", "dual"]
#	var index = 0
	#if Input.is_action_just_pressed("toggle"):
	#	if (len(actionlist) - 1) > index:
	#		index += 1
		#elif (len(actionlist) - 1) < index:
		#	index = 0
	

#POOPY MOVESET
	if not is_on_floor():
		if abs(motion.x) > topspeed:
			motion.x = move_toward(motion.x, topspeed, AIRDRAG)
			
	if is_on_floor():
		canairdash = true
		canstomp = true
	
	if not is_on_floor():
		if Input.is_action_just_pressed("action"):
			if Input.is_action_pressed("down") and canstomp:
				if motion.y < 450:
					motion.y = 450
				elif motion.y >= 450:
					motion.y += 225
					canstomp = false
			elif canairdash:
				motion.x += abs(motion.x) * 0.15 * Input.get_axis("left", "right")
				canairdash = false
	

		

# Movement
	#braking control seen in classic sonic games
	var direction = Input.get_axis("left", "right") # Emits "-1" if holding left, and "1" if holding right.
	
	if direction == -(sign(motion.x)) and (abs(motion.x) >= (topspeed/1.5)) and is_on_floor():
		isskidding = true
	if abs(motion.x) == 0 or (not is_on_floor()) or direction != -(sign(motion.x)):
		isskidding = false
	if isskidding:
		if direction == -(sign(motion.x)):
			motion.x -= dec * sign(motion.x) * 1.3
			
	if direction and not control_lock and not isrolling: # If holding left or right, and not slipping down a slope...
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
		
		
	

# Set Velocity to the Motion variable, but rotated.
	velocity = Vector2(motion.x, motion.y).rotated(rot)
	
	# Right here's where the magic happens.
	# Since Velocity is a Vector2, we've cleverly created a separate Vector2 called "Motion" to-
	# -take all the commands that Velocity would normally take, to then give it right back to-
	# -Velocity with an added ".rotated()" function, which effortlessly rotates Motion based on
	# -your actual rotation, therefore letting you run up walls and stuff.


#rolling
	if Input.is_action_pressed("down") and is_on_floor() and abs(motion.x) > 25:
		isrolling = true
	if Input.is_action_just_released("down") or not is_on_floor() or abs(motion.x) <= 25:
		isrolling = false
		
# Slopes
	if isrolling:
		SLOPEMULT = 5
	else:
		SLOPEMULT = 2
		
	if is_on_floor() and not stuck:
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
			
			control_lock = true
			$ControlLockTimer.start()
			# Briefly lock the player's controls.
			## We wouldn't want them to awkwardly re-attatch to the wall over and over again.
	else:
		falloffwall = false
	



# Stoppers
	if is_on_ceiling() and not grounded: # If you bonk your head on the ceiling...
		if motion.y < 0: # If you're moving up...
			motion.y = 100
			# Get sent right back down.

	if is_on_wall() and $Collision/WallCast.is_colliding(): # If you bump into a wall...
		motion.x = 0
		# Stop moving.



	animate()
	#slope_failsafe()
	move_and_slide()




# That's the main part of the script done with.
# Now let's move on to extra functions and timer signals.


# Animation
## We don't set the animations in the physics_process() code because that would be messy.

## Like the Amy sprites? I made them myself. Use them if you'd like, I don't care.
## Though, you're obviously intended to swap them out with your own (probably ripped) sprites.

## I mostly just did this part for some visual flair.
## Could you imagine how boring it would be if you were just a box sliding around?

## Anyway, I won't explain every line in this part, but I will explain some of it.

var idle := true
var idleset := false

func animate():
	#if abs(motion.x) > 1: # If you're moving...
		#var direction = Input.get_axis("left", "right")
		#$Sprite.scale.x = sign(motion.x)
		#$Collision.scale.x = sign(motion.x)
		# Set Sprite scale and Collision scale based your direction.
		# This is how the Sprite is able to turn when you move.
	var direction = Input.get_axis("left", "right")
	if direction < 0:
		$Sprite.flip_h = true
	elif direction > 0:
		$Sprite.flip_h = false
	
	if isskidding:
		$Sprite.play("idle")
	
	if isrolling:
		$Sprite.play("jump")
		$Sprite.speed_scale = abs(motion.x) / 80
		
	elif grounded:
		if abs(motion.x) < 1: # If you're standing still, or at least EXTREMELY CLOSE to standing still...
			$Sprite.speed_scale = 1
			# Reset the Speed Scale.
			
		elif abs(motion.x) < topspeed - 10: # If you're moving, but not at your Top Speed yet...
			$Sprite.play("walk")
			$Sprite.speed_scale = 0.5 + (abs(motion.x) / 350)
			# Play Walking Animation at half speed, quickening it as you move faster and faster.
			
		elif abs(motion.x) >= topspeed: # If you've reached, or are at least close enough to your Top Speed...
			$Sprite.play("run")
			$Sprite.speed_scale = abs(motion.x)/90
			# Play Running Animation, quickening it even further if you escalate past your Top Speed.
	elif jumping:
		$Sprite.play("jump")
		if abs(motion.x) <= 0:
			$Sprite.speed_scale = 1
		else:
			$Sprite.speed_scale = abs(motion.x) / 80
	
	# Idle animation
	
	if grounded and abs(motion.x) < 1:
		idle = true
	else:
		idle = false
	
	if idle:
		if idleset:
			$Sprite.play("idle")
			idleset = false
		
		if $IdleTimer.is_stopped():
			$IdleTimer.start()
	else:
		idleset = true
		$IdleTimer.stop()


func _on_idle_timer_timeout():
	if abs(motion.x) < 1:
		$Sprite.play("idleanim")




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

#death animation
func deathanim():
	$Collision.set_deferred("disabled", true)
	control_lock = true
	$Sprite.play("idle")
	motion.y = -500
	motion.x = 0

#Fairer Cemera

# WARNING
## I tucked this part at the bottom of the script since this is just for a pretty rare scenario.
## Basically, if you ran down a slope that looks like THIS:
##
##                                |
## _ _ _ _ _ _ _ _ _ _ _ _        |
##                         \      |
##                           \    |
##                             \  |
##                               \|
##
## ...You'll get trapped in the corner forever. And get stuck in the wall.
##  So... please don't do that.


# I tried to write a thing to fix this:
func slope_failsafe():
	if is_on_floor() and ($Collision/WallCast.is_colliding() and abs(rot) > 0.4):
		if abs(motion.x) > 100 and sign(rot) == sign(motion.x):
			stuck = true
			motion.x = -sign(slopefactor) * motion.x
			# It basically just reverses your movement if you get stuck.
	else:
		stuck = false
# ...but it kinda broke something else. So I disabled it. Oh well.





## Thanks for downloading.
## I made this because I was sick of there being no tutorials on how to make Sonic physics in Godot.
## Hope my comments were helpful.
## Have fun developing!!
## - Maddie
