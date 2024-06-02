class_name Rhombully
extends RigidBody2D


enum Phase {
	CHILLING,
	SPINNING_C,
	SPINNING_CC,
	LAUNCHING,
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
@export var attack_delay_max := 4.0
@export var attack_window := 0.08

@export_group("Spin")
@export var spin_range_qdr := 1100.0 ** 2
@export var angular_speed := 10.0
@export var total_spin_radians := 5 * PI

@export_group("Launch")
@export var launch_range_qdr := 1800.0 ** 2
@export var launch_end_dist := 4000.0
@export var second_launch_wait := 1.0
@export var grow_time := 0.5
@export var launch_time := 1.5
@export var launch_scale_factor := 1.5
@export var launch_chance_in_spin_range := 0.25

var attack_delay := 0.0
var phase := Phase.CHILLING
var total_spin := 0.0
var is_launching := false
var launch_with_l := true

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
			if randf() < launch_chance_in_spin_range:
				init_launch_attack()
			else:
				init_spin_attack()
		elif quadrance <= launch_range_qdr:
			init_launch_attack()
	elif phase == Phase.SPINNING_C:
		spin_attack(delta, true)
	elif phase == Phase.SPINNING_CC:
		spin_attack(delta, false)
	elif phase == Phase.LAUNCHING:
		launch_attack()
	elif phase == Phase.DELAYING:
		attack_delay -= delta
		if attack_delay <= 0.0:
			phase = Phase.CHILLING


func _on_hit_area_l_body_entered(body: Node2D) -> void:
	_hit_area_entered(body, hit_area_l)


func _on_hit_area_r_body_entered(body: Node2D) -> void:
	_hit_area_entered(body, hit_area_r)


func _hit_area_entered(body: Node2D, hit_area: Area2D) -> void:
	if phase == Phase.SPINNING_C or phase == Phase.SPINNING_CC or phase == Phase.LAUNCHING:
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
	hand_l.scale = normal_hand_l_scale * launch_scale_factor
	hand_r.scale = normal_hand_r_scale * launch_scale_factor
	phase = Phase.SPINNING_C if clockwise else Phase.SPINNING_CC


func init_launch_attack() -> void:
	phase = Phase.ASYNCING
	animation_player.play(&"telegraph_launch", -1, 0.5)
	reset_delay()
	AudioManager.play_sfx_random_pitch("enemy_attack", 1.0)
	await animation_player.animation_finished
	phase = Phase.LAUNCHING


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


func launch_attack() -> void:
	if not is_launching:
		is_launching = true
		if launch_with_l:
			var trajectory := player.global_position - hand_l.global_position
			trajectory = trajectory.normalized() * launch_end_dist
			var target = hand_l.global_position + trajectory
			var launch_tween = create_tween()
			launch_tween.tween_property(hand_l, "global_position", target, launch_time)
			launch_tween.parallel().tween_property(hand_l, "scale",\
					normal_hand_l_scale * launch_scale_factor, launch_time)
			launch_tween.finished.connect(launch_finish.bind(true))
			await get_tree().create_timer(second_launch_wait).timeout
			launch_with_l = false
			is_launching = false
		else:
			var trajectory := player.global_position - hand_r.global_position
			trajectory = trajectory.normalized() * launch_end_dist
			var target = hand_r.global_position + trajectory
			var launch_tween = create_tween()
			launch_tween.tween_property(hand_r, "global_position", target, launch_time)
			launch_tween.parallel().tween_property(hand_r, "scale",\
					normal_hand_r_scale * launch_scale_factor, launch_time)
			launch_tween.finished.connect(launch_finish.bind(false))


func launch_finish(with_l: bool) -> void:
	if with_l:
		hand_l.scale = Vector2.ZERO
		hand_l.position = normal_hand_l_position
		var grow_tween = create_tween()
		grow_tween.tween_property(hand_l, "scale", normal_hand_l_scale, grow_time)
		grow_tween.finished.connect(end_launch)
	else:
		hand_r.scale = Vector2.ZERO
		hand_r.position = normal_hand_r_position
		var grow_tween = create_tween()
		grow_tween.tween_property(hand_r, "scale", normal_hand_r_scale, grow_time)
		grow_tween.finished.connect(end_launch)


func end_launch() -> void:
	if not launch_with_l:
		launch_with_l = true
		is_launching = false
		animation_player.play(&"RESET")
		phase = Phase.DELAYING
