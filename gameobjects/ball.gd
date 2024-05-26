class_name Ball
extends RigidBody2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_overlapping(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_overlapping(self)


func launch(strength: Vector2) -> void:
	apply_central_force(strength)
