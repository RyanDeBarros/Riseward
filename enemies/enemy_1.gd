class_name Enemy1
extends RigidBody2D


@onready var level := get_tree().get_first_node_in_group(&"level") as Level


func _physics_process(delta: float) -> void:
	if position.y > level.deathzone_y:
		queue_free()


func _process(delta: float) -> void:
	pass
