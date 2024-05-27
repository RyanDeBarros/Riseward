class_name Enemy1
extends RigidBody2D


@export var hit_strength := 3000.0

@onready var level := get_tree().get_first_node_in_group(&"level") as Level
@onready var hit_area_l: Area2D = $HandL/HitAreaL
@onready var hit_area_r: Area2D = $HandR/HitAreaR


func _physics_process(delta: float) -> void:
	if position.y > level.deathzone_y:
		queue_free()


func _on_hit_area_l_body_entered(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - hit_area_l.global_position).normalized()
		body.bounce_back(direction * hit_strength)


func _on_hit_area_r_body_entered(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - hit_area_r.global_position).normalized()
		body.bounce_back(direction * hit_strength)
