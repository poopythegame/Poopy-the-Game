extends Node
class_name AirdashParticlesManager

const particle_prefab_path: String = "uid://dhbvfou3bis7a"

@onready var particle_prefab: PackedScene = load(particle_prefab_path)

# Local space
var target_position: Vector2
var parent: Player

func _ready() -> void:
	var target_position_node: Node2D = $TargetPosition
	target_position = target_position_node.position
	parent = get_parent()

func spawn() -> void:
	var instance: AnimatedSprite2D = particle_prefab.instantiate()
	instance.global_position = parent.global_position + target_position.rotated(parent.sprite.rotation)
	instance.animation_finished.connect(instance.queue_free)
	instance.rotation = parent.sprite.rotation
	instance.flip_h = parent.sprite.flip_h
	add_child(instance)
	parent.process_mode = Node.PROCESS_MODE_DISABLED
