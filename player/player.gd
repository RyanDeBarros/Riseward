class_name Player
extends CharacterBody2D


@export var body_radius := 80.0
@export var throw_angular_factor := 1.5

@export_group("Parrying & Stunning")
@export var stun_total_time := 0.8
@export var parry_recovery_factor := 0.5
@export var parry_force_reduction := 0.5
@export var parry_cooldown := 0.5
@export var parry_reposte_factor := 0.5

@export_group("Dashing", "dash_")
@export var dash_speed := 5000.0
@export var dash_time := 0.15
@export var dash_cooldown := 1.0
@export var dash_end_speed := 1300.0
@export var dash_max_air_dashes := 1

@export_group("Jumping & Airtime")
@export var max_air_jumps := 3
@export var jump_initial_speed := [1300.0, 1150.0, 1000.0, 850.0]
@export var jump_deceleration := [1300.0, 1150.0, 1000.0, 850.0]
@export var fall_acceleration := 1600.0
@export var launch_deceleration := 80.0
@export var jump_consume_factor := 0.8

@export_group("Angular Motion", "angular_")
@export var angular_acceleration := 5.0
@export var angular_deceleration := 20.0
@export var angular_slowdown := 3.0
@export var angular_max_velocity := 20.0
@export var angular_inair_factor := 1.8

var angular_velocity := 0.0

var overlapping_nodes := [] as Array[RigidBody2D]
var left_hand_node: RigidBody2D
var right_hand_node: RigidBody2D

var can_let_go_left := {true: true, false: true}

var dash_current_time := 0.0
var dash_num_air_dashed = 0
enum DashPhase {
	CAN_DASH,
	IS_DASHING,
	DASH_COOLDOWN
}
var dash_phase := DashPhase.CAN_DASH
var dash_velocity: Vector2

var stun_time := 0.0
var is_parrying := false
var can_parry := true

@onready var level := get_tree().get_first_node_in_group(&"level") as Level
@onready var jumps_left := max_air_jumps
@onready var grabber_l: Node2D = $BlueBodyCircle/HandL/GrabberL
@onready var grabber_r: Node2D = $BlueBodyCircle/HandR/GrabberR
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _process(delta: float) -> void:
	if position.y > level.deathzone_y:
		_reload_scene()


func _reload_scene() -> void:
	set_process_input(false)
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_backspace"):
		_reload_scene()
	if event.is_action_pressed("pickup_left"):
		pickup(true)
	elif event.is_action_pressed("action_left"):
		action(true)
	if event.is_action_pressed("pickup_right"):
		pickup(false)
	elif event.is_action_pressed("action_right"):
		action(false)
	if event.is_action_pressed("dash"):
		dash()
	if event.is_action_pressed("parry"):
		parry()


func _physics_process(delta: float) -> void:
	_apply_locomotion(delta)
	if is_on_floor():
		jumps_left = max_air_jumps
		dash_num_air_dashed = 0
	_try_jump()
	_apply_gravity(delta)
	update_dashing(delta)
	update_stun(delta)
	move_and_slide()


func _apply_locomotion(delta: float) -> void:
	var move_axis := Input.get_axis("move_left", "move_right") if is_processing_input() else 0.0
	var change := _calculate_change_in_angular_velocity(move_axis, delta)\
			* (angular_inair_factor if not is_on_floor() else 1.0)
	angular_velocity = clampf(angular_velocity + change,\
			-angular_max_velocity, angular_max_velocity)
	rotation += angular_velocity * delta
	if is_on_floor() and stun_time <= 0.0:
		velocity.x = angular_velocity * body_radius


func _try_jump() -> void:
	if is_processing_input() and Input.is_action_just_pressed("jump")\
			and (is_on_floor() or jumps_left > 0) and stun_time <= 0.0:
		if not is_on_floor():
			jumps_left -= 1
		velocity.y = (1 - jump_consume_factor) * (1 if velocity.y < 0 else 0.5) * velocity.y\
				- jump_consume_factor * jump_initial_speed[max_air_jumps - jumps_left]
		velocity.x = (1 - jump_consume_factor)\
				* (1 if signf(velocity.x) == signf(angular_velocity) else 0.5) * velocity.x\
				+ jump_consume_factor * angular_velocity * body_radius


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
	move_and_slide()


func pickup(left_handed: bool) -> void:
	if not can_let_go_left[left_handed] and (left_hand_node if left_handed else right_hand_node):
		return
	var to_pickup: RigidBody2D
	if not overlapping_nodes.is_empty():
		to_pickup = overlapping_nodes[0]
		overlapping_nodes.remove_at(0)
	let_go_hand(left_handed)
	if left_handed:
		left_hand_node = to_pickup
	else:
		right_hand_node = to_pickup
	if (left_handed and left_hand_node) or (not left_handed and right_hand_node):
		if left_handed:
			left_hand_node.reparent(grabber_l)
			left_hand_node.rotation = left_hand_node.grab_rotation
			left_hand_node.freeze = true
		else:
			right_hand_node.reparent(grabber_r)
			right_hand_node.rotation = right_hand_node.grab_rotation + PI
			right_hand_node.freeze = true
		var collision := (left_hand_node if left_handed else right_hand_node)\
				.find_child("RBCollision") as CollisionShape2D
		if collision:
			collision.disabled = true
		if left_handed:
			left_hand_node.position = Vector2.ZERO
		else:
			right_hand_node.position = Vector2.ZERO


func let_go_hand(left_handed: bool) -> void:
	if can_let_go_left[left_handed] and ((left_handed and left_hand_node)\
			or (not left_handed and right_hand_node)):
		if left_handed:
			overlapping_nodes.append(left_hand_node)
			left_hand_node.reparent(get_tree().get_first_node_in_group(&"level"))
			left_hand_node.freeze = false
		else:
			overlapping_nodes.append(right_hand_node)
			right_hand_node.reparent(get_tree().get_first_node_in_group(&"level"))
			right_hand_node.freeze = false
		var collision := (left_hand_node if left_handed else right_hand_node)\
				.find_child("RBCollision") as CollisionShape2D
		if collision:
			collision.disabled = false
		if left_handed:
			left_hand_node = null
		else:
			right_hand_node = null


func action(left_handed: bool) -> void:
	if is_parrying:
		return
	if (left_handed and left_hand_node is Ball) or (not left_handed and right_hand_node is Ball):
		launch_ball(left_handed)
	elif (left_handed and left_hand_node is Bat) or (not left_handed and right_hand_node is Bat):
		swing_bat(left_handed)


func launch_ball(left_handed: bool) -> void:
	var direction := get_local_mouse_position().rotated(rotation).normalized()
	var strength := 100000 * (1 + throw_angular_factor\
			* abs(angular_velocity / angular_max_velocity)) as float
	if left_handed:
		left_hand_node.launch(strength * direction)
	else:
		right_hand_node.launch(strength * direction)
	let_go_hand(left_handed)


func swing_bat(left_handed: bool) -> void:
	can_let_go_left[left_handed] = false
	(left_hand_node if left_handed else right_hand_node).is_attacking(self)
	if left_handed:
		if angular_velocity >= 0:
			animation_player.play_backwards(&"swing_l")
		else:
			animation_player.play(&"swing_l")
	else:
		if angular_velocity <= 0:
			animation_player.play_backwards(&"swing_r")
		else:
			animation_player.play(&"swing_r")
	await animation_player.animation_finished
	can_let_go_left[left_handed] = true
	(left_hand_node if left_handed else right_hand_node).is_attacking(null)


func add_overlapping(node: RigidBody2D) -> void:
	if left_hand_node != node and right_hand_node != node:
		overlapping_nodes.append(node)


func remove_overlapping(node: RigidBody2D) -> void:
	overlapping_nodes.erase(node)


func dash() -> void:
	if dash_phase == DashPhase.CAN_DASH and stun_time <= 0.0\
			and (is_on_floor() or dash_num_air_dashed < dash_max_air_dashes):
		dash_phase = DashPhase.IS_DASHING
		dash_current_time = 0.0
		dash_velocity = velocity + dash_speed * get_local_mouse_position().rotated(rotation).normalized()
		if not is_on_floor() or dash_velocity.y < 0:
			dash_num_air_dashed += 1
		velocity = dash_velocity
		move_and_slide()


func update_dashing(delta: float) -> void:
	if dash_phase == DashPhase.IS_DASHING:
		if dash_current_time < dash_time:
			velocity = dash_velocity
			dash_current_time += delta
		else:
			dash_phase = DashPhase.DASH_COOLDOWN
			dash_current_time = 0.0
			velocity = dash_end_speed * velocity.normalized()
	elif dash_phase == DashPhase.DASH_COOLDOWN:
		if dash_current_time < dash_cooldown:
			dash_current_time += delta
		else:
			dash_phase = DashPhase.CAN_DASH


func parry() -> void:
	if not is_parrying and can_parry:
		is_parrying = true
		can_parry = false
		animation_player.play(&"parry")
		await animation_player.animation_finished
		is_parrying = false
		await get_tree().create_timer(parry_cooldown).timeout
		can_parry = true


func bounce_back(force: Vector2) -> Vector2:
	var reply := Vector2.ZERO
	if is_parrying:
		print('parry success')
		reply = -parry_reposte_factor * force
		force *= parry_force_reduction
		stun_time = parry_recovery_factor * stun_total_time
		
	else:
		print('parry fail')
		stun_time = stun_total_time
	if is_on_floor():
		global_position.y -= 1
		velocity = Vector2(force.length() * signf(force.x), -1000)
	elif is_on_ceiling():
		global_position.y += 1
		velocity = Vector2(force.length() * signf(force.x), 1000)
	else:
		velocity = force
	move_and_slide()
	jumps_left = max_air_jumps - 1
	dash_num_air_dashed = 0
	return reply


func update_stun(delta: float) -> void:
	if stun_time > 0.0:
		stun_time -= delta
