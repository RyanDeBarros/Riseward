class_name Enemy1
extends RigidBody2D


@export var hit_strength := 3000.0

@onready var level := get_tree().get_first_node_in_group(&"level") as Level
@onready var hit_area_l: Area2D = $HandL/HitAreaL
@onready var hit_area_r: Area2D = $HandR/HitAreaR

#var hitting_player_l: Player
#var hitting_player_r: Player


#func _physics_process(delta: float) -> void:
	#if position.y > level.deathzone_y:
		#queue_free()
	#if hitting_player_l:
		#var direction := (hitting_player_l.global_position - hit_area_l.global_position).normalized()
		#hitting_player_l.bounce_back(direction * hit_strength)
	#elif hitting_player_r:
		#var direction := (hitting_player_r.global_position - hit_area_r.global_position).normalized()
		#hitting_player_r.bounce_back(direction * hit_strength)


func _on_hit_area_l_body_entered(body: Node2D) -> void:
	if body is Player:
		#hitting_player_l = body
		var direction := (body.global_position - hit_area_r.global_position).normalized()
		body.bounce_back(direction * hit_strength)


func _on_hit_area_r_body_entered(body: Node2D) -> void:
	if body is Player:
		#hitting_player_r = body
		var direction := (body.global_position - hit_area_r.global_position).normalized()
		body.bounce_back(direction * hit_strength)

#
#func _on_hit_area_l_body_exited(body: Node2D) -> void:
	#if body is Player:
		#hitting_player_l = null
#
#
#func _on_hit_area_r_body_exited(body: Node2D) -> void:
	#if body is Player:
		#hitting_player_r = null
