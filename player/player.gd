class_name Player
extends CharacterBody2D


@export var body_radius := 80.0

@export_group("Combat")
@export var throw_angular_factor := 1.5
@export var swing_cooldown := 0.15

@export_group("Parrying & Stunning")
@export var parry_recovery_factor := 0.3
@export var parry_force_reduction := 0.3
@export var parry_cooldown := 0.7
@export var parry_reposte_factor := 0.5
@export var parry_window_scale_factor := 0.85

@export_group("Dashing", "dash_")
@export var dash_speed := 5000.0
@export var dash_time := 0.15
@export var dash_cooldown := 1.6
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

var dead := false

var angular_velocity := 0.0

var overlapping_nodes := [] as Array[Node2D]
var left_hand_node: Node2D
var right_hand_node: Node2D

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

var pending_parries := {}
var pending_index := 0

var can_swing := true

@onready var level := get_tree().get_first_node_in_group(&"level") as Level
@onready var jumps_left := max_air_jumps
@onready var grabber_l: Node2D = $BlueBodyCircle/HandL/GrabberL
@onready var grabber_r: Node2D = $BlueBodyCircle/HandR/GrabberR
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_2d: Camera2D = $Camera2D


func _ready() -> void:
	var bkg = get_tree().get_first_node_in_group(&"bkg") as Sprite2D
	camera_2d.limit_bottom = 0
	camera_2d.limit_top = -bkg.texture.get_height() * bkg.scale.y
	camera_2d.limit_left = -bkg.texture.get_width() * bkg.scale.x * 0.5
	camera_2d.limit_right = bkg.texture.get_width() * bkg.scale.x * 0.5


func _process(delta: float) -> void:
	if position.y > body_radius:
		die()
	if is_parrying:
		for i in pending_parries.keys():
			pending_parries[i] = true


func _reload_scene() -> void:
	set_process_input(false)
	set_process(false)
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
		velocity.y = (1 - jump_consume_factor) * (1.0 if velocity.y < 0 else 0.5) * velocity.y\
				- jump_consume_factor * jump_initial_speed[max_air_jumps - jumps_left]
		velocity.x = (1 - jump_consume_factor)\
				* (1.0 if signf(velocity.x) == signf(angular_velocity) else 0.5) * velocity.x\
				+ jump_consume_factor * angular_velocity * body_radius
		AudioManager.play_sfx_random_pitch("jump", -2.0)


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
	AudioManager.play_sfx_random_pitch("jump", -2.0)


func pickup(left_handed: bool) -> void:
	if not can_let_go_left[left_handed] and (left_hand_node if left_handed else right_hand_node):
		return
	var to_pickup: Node2D
	if not overlapping_nodes.is_empty():
		for i in range(len(overlapping_nodes)):
			if overlapping_nodes[i].is_in_group(&"item"):
				to_pickup = overlapping_nodes[i]
				overlapping_nodes.remove_at(i)
				break
	var did_drop := let_go_hand(left_handed)
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
	if to_pickup:
		to_pickup.pickup()
		if did_drop:
			AudioManager.play_sfx_random_pitch("swap", 2.0)
		else:
			AudioManager.play_sfx_random_pitch("pickup")
	elif did_drop:
		AudioManager.play_sfx_random_pitch("drop", 6.5)


func let_go_hand(left_handed: bool) -> bool:
	if can_let_go_left[left_handed] and ((left_handed and left_hand_node)\
			or (not left_handed and right_hand_node)):
		if left_handed:
			overlapping_nodes.append(left_hand_node)
			left_hand_node.reparent(get_tree().get_first_node_in_group(&"items_dir"))
			left_hand_node.freeze = false
			left_hand_node.let_go()
		else:
			overlapping_nodes.append(right_hand_node)
			right_hand_node.reparent(get_tree().get_first_node_in_group(&"items_dir"))
			right_hand_node.freeze = false
			right_hand_node.let_go()
		var collision := (left_hand_node if left_handed else right_hand_node)\
				.find_child("RBCollision") as CollisionShape2D
		if collision:
			collision.disabled = false
		if left_handed:
			left_hand_node = null
		else:
			right_hand_node = null
		return true
	else:
		return false


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
	AudioManager.play_sfx_random_pitch("throw")


func swing_bat(left_handed: bool) -> void:
	if not can_swing:
		return
	can_swing = false
	can_let_go_left[left_handed] = false
	if randi_range(0, 1) == 0:
		AudioManager.play_sfx_random_pitch("swing1", 1.0, 0.3)
	else:
		AudioManager.play_sfx_random_pitch("swing2", 0.0, 0.0)
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
	await get_tree().create_timer(swing_cooldown).timeout
	can_swing = true


func add_overlapping(node: Node2D) -> void:
	if left_hand_node != node and right_hand_node != node:
		overlapping_nodes.append(node)


func remove_overlapping(node: Node2D) -> void:
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
		AudioManager.play_sfx_random_pitch("dash", 1.0)
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
		AudioManager.play_sfx_random_pitch("parry", 3.0)
		check_for_itembox()
		animation_player.play(&"parry", -1, parry_window_scale_factor)
		await animation_player.animation_finished
		is_parrying = false
		await get_tree().create_timer(parry_cooldown).timeout
		can_parry = true


func check_for_itembox() -> void:
	for node in overlapping_nodes:
		if node is ItemBox:
			node.pop()


func bounce_back(force: Vector2, attack_window := 0.0, stun_total_time := 0.8,\
		parry_improvement := 1.0) -> Vector2:
	var i := pending_index
	pending_index += 1
	pending_parries[i] = false
	await get_tree().create_timer(attack_window).timeout
	var reply := Vector2.ZERO
	var parried := pending_parries[i] as bool
	pending_parries.erase(i)
	if parried:
		AudioManager.play_sfx_random_pitch("parry_success", 0.0, 0.0, 0.9, 1.1, 0.8)
		reply = -parry_reposte_factor * force
		force = force * parry_force_reduction / parry_improvement
		stun_time = parry_recovery_factor * stun_total_time / parry_improvement
	else:
		AudioManager.play_sfx_random_pitch("player_hit")
		lose_random_item()
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


func lose_random_item() -> void:
	if not left_hand_node:
		if right_hand_node:
			call_deferred("let_go_hand", false)
	else:
		if not right_hand_node:
			call_deferred("let_go_hand", true)
		else:
			call_deferred("let_go_hand", true if randi_range(0, 1) == 0 else false)


func die() -> void:
	if not dead:
		dead = true
		_reload_scene()
		AudioManager.play_sfx("death")
