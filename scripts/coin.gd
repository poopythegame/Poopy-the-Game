extends Node2D

@export var heal_amount := 5.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var animation_duration := 1.5
var used: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	var area_2d = $Area2D
	area_2d.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Player and not used:
		# a player picked up the coin
		animated_sprite_2d.play("spin")
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0, animation_duration)
		tween.parallel().tween_property(self, "position:y", position.y - 50, animation_duration)
		tween.tween_callback(hide)
		used = true
		if body.health < body.max_health:
			body.health += 5
		# This automatically adds the coin to the correct level "bucket"
		Global.add_coin()
