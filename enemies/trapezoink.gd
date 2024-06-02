class_name Trapezoink
extends RigidBody2D


enum Phase {
	CHILLING,
	SPINNING_C,
	SPINNING_CC,
	HOMING,
	DELAYING,
	ASYNCING
}

@export_group("Player Collision")
@export var hit_strength := 4000.0
@export var ball_hit_strength := 240000.0
@export var reposte_susceptibility := 20.0
@export var face_max_x := 30.0
@export var stun_time := 1.2
@export var parry_improvement := 1.5

@export_group("Attack")
@export var attack_delay_min := 1.0
@export var attack_delay_max := 3.3
@export var attack_window := 0.08

@export_group("Spin")
@export var spin_range_qdr := 1100.0 ** 2
@export var angular_speed := 10.0
@export var total_spin_radians := 5 * PI

@export_group("Homing")
@export var homing_range_qdr := 1800.0 ** 2
@export var homing_lock_on_time := 0.75
@export var homing_continue_time := 0.75
@export var homing_return_time := 0.8
@export var homing_scale_factor := 1.5
@export var homing_chance_in_spin_range := 0.25
@export var fist_speed := 2000.0

var attack_delay := 0.0
var phase := Phase.CHILLING
var total_spin := 0.0
var homing_with_l := true
var lock_on_time_l := 0.0
var lock_on_time_r := 0.0
var continue_time_l := 0.0
var continue_time_r := 0.0
var return_time_l := 0.0
var return_time_r := 0.0
var trajectory_l: Vector2
var trajectory_r: Vector2
var return_from_position_l: Vector2
var return_from_position_r: Vector2

@onready var level := get_tree().get_first_node_in_group(&"level") as Level
@onready var face: Node2D = $Face
@onready var hand_l: Node2D = $HandL
@onready var hand_r: Node2D = $HandR
@onready var hit_area_l: Area2D = $HandL/HitAreaL
@onready var hit_area_r: Area2D = $HandR/HitAreaR
@onready var hit_collision_l: CollisionShape2D = $HandL/HitAreaL/HitCollisionL
@onready var hit_collision_r: CollisionShape2D = $HandR/HitAreaR/HitCollisionR
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player := get_tree().get_first_node_in_group(&"player") as Player
@onready var normal_hand_l_scale := hand_l.scale
@onready var normal_hand_r_scale := hand_r.scale
@onready var normal_hand_l_position := hand_l.position
@onready var normal_hand_r_position := hand_r.position


func _ready() -> void:
	level.enemy_list.push_back(self)


func _process(delta: float) -> void:
	if global_position.y > 100:
		level.enemy_list.erase(self)
		queue_free()
	look_at_player()
	if phase == Phase.CHILLING:
		var quadrance := (player.global_position - global_position).length_squared()
		if quadrance <= spin_range_qdr:
			if randf() < homing_chance_in_spin_range:
				init_homing_attack()
			else:
				init_spin_attack()
		elif quadrance <= homing_range_qdr:
			init_homing_attack()
	elif phase == Phase.SPINNING_C:
		spin_attack(delta, true)
	elif phase == Phase.SPINNING_CC:
		spin_attack(delta, false)
	elif phase == Phase.HOMING:
		homing_attack(delta)
	elif phase == Phase.DELAYING:
		attack_delay -= delta
		if attack_delay <= 0.0:
			phase = Phase.CHILLING


func _on_hit_area_l_body_entered(body: Node2D) -> void:
	_hit_area_entered(body, hit_area_l)


func _on_hit_area_r_body_entered(body: Node2D) -> void:
	_hit_area_entered(body, hit_area_r)


func _hit_area_entered(body: Node2D, hit_area: Area2D) -> void:
	if phase == Phase.SPINNING_C or phase == Phase.SPINNING_CC or phase == Phase.HOMING:
		if body is Player:
			var direction := (body.global_position - hit_area.global_position).normalized()
			player.bounce_back(direction * hit_strength, attack_window, stun_time, parry_improvement)
		elif body is Ball:
			var direction := (body.global_position - hit_area.global_position).normalized()
			body.apply_central_force(direction * ball_hit_strength)
	if body is Ball or body is Bat:
		AudioManager.play_sfx_random_pitch("enemy_hit", -3.0)


func _on_bounce_back_area_body_entered(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - global_position).normalized()
		var reposte := await player.bounce_back(direction * hit_strength, attack_window,\
				stun_time, parry_improvement)
		reposte = Vector2(reposte.x, 0)
		if reposte.x != 0.0:
			AudioManager.play_sfx_random_pitch("enemy_hit")
		apply_central_force(reposte * mass * reposte_susceptibility)


func look_at_player() -> void:
	var player_delta := clampf(player.global_position.x - global_position.x,\
			-face_max_x, face_max_x)
	face.position.x = player_delta
	face.scale.x = signf(player_delta)


func reset_delay() -> void:
	attack_delay = randf_range(attack_delay_min, attack_delay_max)


func init_spin_attack() -> void:
	phase = Phase.ASYNCING
	var clockwise := randi_range(0, 1) == 0
	if clockwise:
		animation_player.play(&"telegraph_spin_C")
	else:
		animation_player.play(&"telegraph_spin_CC")
	reset_delay()
	total_spin = 0
	AudioManager.play_sfx_random_pitch("enemy_attack", 1.0)
	await animation_player.animation_finished
	hand_l.position.x = normal_hand_l_position.x - 40
	hand_r.position.x = normal_hand_r_position.x + 40
	hand_l.scale = normal_hand_l_scale * homing_scale_factor
	hand_r.scale = normal_hand_r_scale * homing_scale_factor
	phase = Phase.SPINNING_C if clockwise else Phase.SPINNING_CC


func init_homing_attack() -> void:
	phase = Phase.ASYNCING
	animation_player.play(&"telegraph_homing", -1, 0.5)
	reset_delay()
	homing_with_l = true
	lock_on_time_l = 0.0
	lock_on_time_r = 0.0
	continue_time_l = 0.0
	continue_time_r = 0.0
	return_time_l = 0.0
	return_time_r = 0.0
	AudioManager.play_sfx_random_pitch("enemy_attack", 1.0)
	await animation_player.animation_finished
	phase = Phase.HOMING


func spin_attack(delta: float, clockwise: bool) -> void:
	if total_spin >= total_spin_radians:
		hand_l.position = normal_hand_l_position
		hand_r.position = normal_hand_r_position
		hand_l.scale = normal_hand_l_scale
		hand_r.scale = normal_hand_r_scale
		animation_player.play(&"RESET")
		phase = Phase.DELAYING
	else:
		var dtheta := angular_speed * delta * (1 if clockwise else -1)
		total_spin += abs(dtheta)
		hand_l.position = hand_l.position.rotated(dtheta)
		hand_r.position = hand_r.position.rotated(dtheta)


func homing_attack(delta: float) -> void:
	if homing_with_l:
		if lock_on_time_l < homing_lock_on_time:
			lock_on_time_l += delta
			trajectory_l = player.global_position - hand_l.global_position
			trajectory_l = trajectory_l.normalized() * fist_speed * delta
			hand_l.global_position += trajectory_l
			hand_l.rotation = trajectory_l.angle()
			hand_l.scale = normal_hand_l_scale * lerpf(1.0, homing_scale_factor,\
					lock_on_time_l / homing_lock_on_time)
		elif continue_time_l < homing_continue_time:
			continue_time_l += delta
			hand_l.global_position += trajectory_l.normalized() * fist_speed * delta
			if continue_time_l >= homing_continue_time:
				hit_collision_l.disabled = true
				return_from_position_l = hand_l.position
		elif return_time_l < homing_return_time:
			return_time_l += delta
			hand_l.position = lerp(return_from_position_l, normal_hand_l_position,\
					return_time_l / homing_return_time)
			hand_l.scale = normal_hand_l_scale * lerpf(homing_scale_factor, 1.0,\
					return_time_l / homing_return_time)
		else:
			hand_l.rotation = 0
			hit_collision_l.disabled = false
			homing_with_l = false
	else:
		if lock_on_time_r < homing_lock_on_time:
			lock_on_time_r += delta
			trajectory_r = player.global_position - hand_r.global_position
			trajectory_r = trajectory_r.normalized() * fist_speed * delta
			hand_r.global_position += trajectory_r
			hand_r.rotation = trajectory_r.angle()
			hand_r.scale = normal_hand_r_scale * lerpf(1.0, homing_scale_factor,\
					lock_on_time_r / homing_lock_on_time)
		elif continue_time_r < homing_continue_time:
			continue_time_r += delta
			hand_r.global_position += trajectory_r.normalized() * fist_speed * delta
			if continue_time_r >= homing_continue_time:
				hit_collision_r.disabled = true
				return_from_position_r = hand_r.position
		elif return_time_r < homing_return_time:
			return_time_r += delta
			hand_r.position = lerp(return_from_position_r, normal_hand_r_position,\
					return_time_r / homing_return_time)
			hand_r.scale = normal_hand_r_scale * lerpf(homing_scale_factor, 1.0,\
					return_time_r / homing_return_time)
		else:
			hit_collision_r.disabled = false
			animation_player.play(&"RESET")
			phase = Phase.DELAYING
