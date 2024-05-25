class_name Player
extends CharacterBody2D


@export var collision_radius := 80.0

@export var jump_initial_speed := 1200.0
@export var jump_deceleration := 1200.0
@export var fall_acceleration := 1000.0

@export_group("Angular Motion", "angular_")
@export var angular_acceleration := 5.0
@export var angular_deceleration := 20.0
@export var angular_slowdown := 10.0
@export var angular_max_velocity := 15.0

var angular_velocity := 0.0

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _physics_process(delta: float) -> void:
	var move_axis := Input.get_axis("move_left", "move_right")
	var change := calculate_change_in_angular_velocity(move_axis, delta)
	angular_velocity = clampf(angular_velocity + change,\
			-angular_max_velocity, angular_max_velocity)
	rotation += angular_velocity * delta
	if is_on_floor():
		velocity.x = angular_velocity * collision_radius
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()
	if velocity.y < 0.0:
		velocity.y += jump_deceleration * delta
	else:
		velocity.y += fall_acceleration * delta
	move_and_slide()


func jump() -> void:
	velocity.y = -jump_initial_speed


func calculate_change_in_angular_velocity(move_axis: float, delta: float) -> float:
	if move_axis > 0.0:
		if angular_velocity > 0.0:
			return angular_acceleration * delta
		else:
			return angular_deceleration * delta
	elif move_axis < 0.0:
		if angular_velocity < 0.0:
			return -angular_acceleration * delta
		else:
			return -angular_deceleration * delta
	else:
		if angular_velocity > 0.0:
			return -angular_slowdown * delta
		elif angular_velocity < 0.0:
			return angular_slowdown * delta
		else:
			return 0.0
