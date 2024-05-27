class_name Bat
extends RigidBody2D


@export var grab_rotation := -2.0
@export var strength := 5000.0

var owning_player: Player

@onready var impact_collision: CollisionShape2D = $HitArea/ImpactCollision


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_overlapping(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_overlapping(self)


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"enemy") and owning_player:
		var launch_dir := (body.global_position - owning_player.global_position).normalized()
		(body as RigidBody2D).apply_central_impulse(strength * launch_dir)


func is_attacking(player: Player) -> void:
	impact_collision.disabled = (player == null)
	owning_player = player
