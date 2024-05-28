class_name Ball
extends RigidBody2D


@export var grab_rotation := 0.0

@onready var level := get_tree().get_first_node_in_group(&"level") as Level


func _physics_process(delta: float) -> void:
	if global_position.y > level.deathzone_y:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_overlapping(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_overlapping(self)


func launch(strength: Vector2) -> void:
	apply_central_force(strength * mass)
