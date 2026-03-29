extends CharacterBody2D
class_name Player

enum State {
	GROUNDED,
	AIRBORNE,
	GRAPPLE,
}

@export var gravity: float = 850
@export var speed: float = 3
@export var deceleration: float = 1.5
@export var max_speed: float = 850
@export_group("Airborne Physics")
@export var jump_strength: float = 650
@export var coyote_time: float = 0.25
@export var air_control: float = 1

var state: State = State.GROUNDED
var coyote_timer: float = 0
var motion: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $Sprite

func _physics_process(delta: float) -> void:
	if state == State.GROUNDED:
		grounded_physics(delta)
	elif state == State.AIRBORNE:
		airborne_physics(delta)

func grounded_physics(delta: float):
	var n_collisions: int = get_slide_collision_count()
	var angle: float = 0.0
	for i in range(n_collisions):
		var collision: KinematicCollision2D = get_slide_collision(i)
		angle += collision.get_normal().angle()
	angle /= n_collisions
	if n_collisions <= 0:
		angle = 0
	rotation = angle + PI/2
	up_direction = Vector2.from_angle(angle)

	#region Forces
	motion.y += gravity * delta
	if motion.x > 0:
		motion.x -= deceleration
		if motion.x < 0:
			motion.x = 0
	elif motion.x < 0:
		motion.x += deceleration
		if motion.x > 0:
			motion.x = 0
	var dir = Input.get_axis("left", "right")
	motion.x += dir * speed * delta
	if Input.is_action_just_pressed("jump"):
		motion.y -= jump_strength * delta
	#endregion

	var slope: float = up_direction.x
	var dx = motion.x - motion.y * slope
	var dy = motion.y
	velocity.x = clamp(dx, -max_speed, max_speed)
	velocity.y = clamp(dy, -max_speed, max_speed)
	move_and_slide()

	#region Animation
	if abs(motion.x) >= max_speed:
		sprite.play("run")
		sprite.speed_scale = motion.x / 30
	elif abs(motion.x) > 0:
		sprite.play("walk")
		sprite.speed_scale = motion.x / 30
	else:
		sprite.play("idle")
	#endregion

	if !is_on_floor():
		state = State.AIRBORNE
		velocity = Vector2.ZERO
		coyote_timer = coyote_time

func airborne_physics(delta: float):
	velocity.y += gravity
	if velocity.x > 0:
		velocity.x -= deceleration
		if velocity.x < 0:
			velocity.x = 0
	elif velocity.x < 0:
		velocity.x += deceleration
		if velocity.x > 0:
			velocity.x = 0
	rotation = 0
	up_direction = Vector2.UP
	if coyote_timer > 0:
		if Input.is_action_just_pressed("jump"):
			velocity.y -= jump_strength * delta
		var dir = Input.get_axis("left", "right")
		velocity.x += dir * speed * delta
		coyote_time -= delta
	else:
		var dir = Input.get_axis("left", "right")
		velocity.x += dir * speed * air_control * delta
	
	velocity.x = clamp(velocity.x, -max_speed, max_speed)
	velocity.y = clamp(velocity.y, -max_speed, max_speed)
	move_and_slide()
	sprite.play("jump")

	if is_on_floor():
		state = State.GROUNDED
