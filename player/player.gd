class_name Player
extends CharacterBody2D

@export var level: Level

@export var collision_radius := 80.0

@export_group("Jumping & Airtime")
@export var max_air_jumps := 2
@export var jump_initial_speed := [1300.0, 1150.0, 1000.0]
@export var jump_deceleration := [1300.0, 1150.0, 1000.0]
@export var fall_acceleration := 1600.0
@export var launch_deceleration := 80.0

@export_group("Angular Motion", "angular_")
@export var angular_acceleration := 5.0
@export var angular_deceleration := 20.0
@export var angular_slowdown := 3.0
@export var angular_max_velocity := 15.0
@export var angular_inair_factor := 1.8

var angular_velocity := 0.0

var overlapping_nodes := [] as Array[RigidBody2D]
var left_hand_node: RigidBody2D
var right_hand_node: RigidBody2D

@onready var jumps_left := max_air_jumps
@onready var grabber_l: Node2D = $BlueBodyCircle/HandL/GrabberL
@onready var grabber_r: Node2D = $BlueBodyCircle/HandR/GrabberR


func _process(delta: float) -> void:
	if position.y > level.deathzone_y:
		get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_text_backspace"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("pickup_left"):
		pickup_left()
	elif event.is_action_pressed("action_left"):
		action_left()
	if event.is_action_pressed("pickup_right"):
		pickup_right()
	elif event.is_action_pressed("action_right"):
		action_right()


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
		velocity.y = -jump_initial_speed[max_air_jumps - jumps_left]
		velocity.x = angular_velocity * collision_radius


func _apply_gravity(delta: float) -> void:
	if velocity.y < 0.0:
		velocity.y += jump_deceleration[max_air_jumps - jumps_left] * delta
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


func launch(impulse: Vector2) -> void:
	velocity = impulse


func pickup_left() -> void:
	var to_pickup: RigidBody2D
	if not overlapping_nodes.is_empty():
		to_pickup = overlapping_nodes[0]
		overlapping_nodes.remove_at(0)
	let_go_left_hand()
	left_hand_node = to_pickup
	if left_hand_node:
		left_hand_node.reparent(grabber_l)
		left_hand_node.freeze = true
		left_hand_node.position = Vector2.ZERO


func pickup_right() -> void:
	var to_pickup: RigidBody2D
	if not overlapping_nodes.is_empty():
		to_pickup = overlapping_nodes[0]
		overlapping_nodes.remove_at(0)
	let_go_right_hand()
	right_hand_node = to_pickup
	if right_hand_node:
		right_hand_node.reparent(grabber_r)
		right_hand_node.freeze = true
		right_hand_node.position = Vector2.ZERO


func let_go_left_hand() -> void:
	if left_hand_node:
		overlapping_nodes.append(left_hand_node)
		left_hand_node.reparent(get_tree().root)
		left_hand_node.freeze = false
		left_hand_node = null


func let_go_right_hand() -> void:
	if right_hand_node:
		overlapping_nodes.append(right_hand_node)
		right_hand_node.reparent(get_tree().root)
		right_hand_node.freeze = false
		right_hand_node = null


func action_left() -> void:
	if left_hand_node:
		left_hand_node.action()


func action_right() -> void:
	if right_hand_node:
		right_hand_node.action()


func add_overlapping(node: RigidBody2D) -> void:
	if left_hand_node != node and right_hand_node != node:
		overlapping_nodes.append(node)


func remove_overlapping(node: RigidBody2D) -> void:
	overlapping_nodes.erase(node)
