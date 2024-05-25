class_name Player
extends CharacterBody2D

@export var level: Level

@export var collision_radius := 80.0

@export_group("Jumping & Airtime")
@export var max_air_jumps := 2
@export var jump_initial_speed := 1300.0
@export var jump_deceleration := 1300.0
@export var fall_acceleration := 1000.0
@export var launch_deceleration := 100.0

@export_group("Angular Motion", "angular_")
@export var angular_acceleration := 5.0
@export var angular_deceleration := 20.0
@export var angular_slowdown := 3.0
@export var angular_max_velocity := 15.0
@export var angular_inair_factor := 1.8

var angular_velocity := 0.0

@onready var jumps_left := max_air_jumps

 
func _process(delta: float) -> void:
	if position.y > level.deathzone_y:
		get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_text_backspace"):
		get_tree().reload_current_scene()


func _physics_process(delta: float) -> void:
	_apply_locomotion(delta)
	if is_on_floor():
		velocity.x = angular_velocity * collision_radius
		jumps_left = max_air_jumps
	_try_jump()
	_apply_gravity(delta)
	move_and_slide()


func _apply_locomotion(delta: float) -> void:
	var move_axis := Input.get_axis("move_left", "move_right")
	var change := _calculate_change_in_angular_velocity(move_axis, delta)\
			* (angular_inair_factor if not is_on_floor() else 1.0)
	angular_velocity = clampf(angular_velocity + change,\
			-angular_max_velocity, angular_max_velocity)
	rotation += angular_velocity * delta


func _try_jump() -> void:
	if Input.is_action_just_pressed("jump") and (is_on_floor() or jumps_left > 0):
		if not is_on_floor():
			jumps_left -= 1
		velocity.y = -jump_initial_speed
		velocity.x = angular_velocity * collision_radius


func _apply_gravity(delta: float) -> void:
	if velocity.y < 0.0:
		velocity.y += jump_deceleration * delta
	else:
		velocity.y += fall_acceleration * delta


func _calculate_change_in_angular_velocity(move_axis: float, delta: float) -> float:
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


func launch(direction: Vector2, magnitude: float) -> void:
	velocity = direction * magnitude
