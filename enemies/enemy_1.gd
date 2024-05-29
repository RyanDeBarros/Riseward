class_name Enemy1
extends RigidBody2D


enum Phase {
	CHILLING,
	SPINNING_C,
	SPINNING_CC,
	PUNCHING,
	DELAYING,
	ASYNCING
}

@export_group("Player Collision")
@export var hit_strength := 3800.0
@export var ball_hit_strength := 230000.0
@export var reposte_susceptibility := 20.0
@export var face_max_x := 30.0
@export var stun_time := 1.2
@export var parry_improvement := 1.5

@export_group("Attack")
@export var attack_delay_min := 1.0
@export var attack_delay_max := 4.0

@export_group("Spin")
@export var spin_range_qdr := 1200.0 ** 2
@export var angular_speed := 10.0
@export var total_spin_radians := 5 * PI

@export_group("Punch")
@export var punch_range_qdr := 2000.0 ** 2
@export var number_of_punches := 2
@export var punch_time := 0.5
@export var punch_return_time := 0.8
@export var punch_scale_factor := 1.5
@export var punch_chance_in_spin_range := 0.1

var attack_delay := 0.0
var phase := Phase.CHILLING
var total_spin := 0.0
var punch_count := 0
var is_punching := false
var punch_with_l := true

@onready var level := get_tree().get_first_node_in_group(&"level") as Level
@onready var face: Node2D = $Face
@onready var hand_l: Node2D = $HandL
@onready var hand_r: Node2D = $HandR
@onready var hit_area_l: Area2D = $HandL/HitAreaL
@onready var hit_area_r: Area2D = $HandR/HitAreaR
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player := get_tree().get_first_node_in_group(&"player") as Player
@onready var normal_hand_l_scale := hand_l.scale
@onready var normal_hand_r_scale := hand_r.scale
@onready var normal_hand_l_position := hand_l.position
@onready var normal_hand_r_position := hand_r.position


func _process(delta: float) -> void:
	look_at_player()
	if phase == Phase.CHILLING:
		var quadrance := (player.global_position - global_position).length_squared()
		if quadrance <= spin_range_qdr:
			if randf() < punch_chance_in_spin_range:
				init_punch_attack()
			else:
				init_spin_attack()
		elif quadrance <= punch_range_qdr:
			init_punch_attack()
	elif phase == Phase.SPINNING_C:
		spin_attack(delta, true)
	elif phase == Phase.SPINNING_CC:
		spin_attack(delta, false)
	elif phase == Phase.PUNCHING:
		punch_attack()
	elif phase == Phase.DELAYING:
		attack_delay -= delta
		if attack_delay <= 0.0:
			phase = Phase.CHILLING


func _on_hit_area_l_body_entered(body: Node2D) -> void:
	_hit_area_entered(body, hit_area_l)


func _on_hit_area_r_body_entered(body: Node2D) -> void:
	_hit_area_entered(body, hit_area_r)


func _hit_area_entered(body: Node2D, hit_area: Area2D) -> void:
	if phase == Phase.SPINNING_C or phase == Phase.SPINNING_CC or phase == Phase.PUNCHING:
		if body is Player:
			var direction := (body.global_position - hit_area.global_position).normalized()
			player.bounce_back(direction * hit_strength, stun_time, 1)
		elif body is Ball:
			var direction := (body.global_position - hit_area.global_position).normalized()
			body.apply_central_force(direction * ball_hit_strength)


func _on_bounce_back_area_body_entered(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - global_position).normalized()
		var reposte := player.bounce_back(direction * hit_strength, stun_time, parry_improvement)
		reposte = Vector2(reposte.x, 0)
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
	await animation_player.animation_finished
	phase = Phase.SPINNING_C if clockwise else Phase.SPINNING_CC


func init_punch_attack() -> void:
	phase = Phase.ASYNCING
	animation_player.play(&"telegraph_punch", -1, 0.5)
	reset_delay()
	punch_count = 0
	await animation_player.animation_finished
	phase = Phase.PUNCHING


func spin_attack(delta: float, clockwise: bool) -> void:
	if total_spin >= total_spin_radians:
		animation_player.play(&"RESET")
		phase = Phase.DELAYING
	else:
		var dtheta := angular_speed * delta * (1 if clockwise else -1)
		total_spin += abs(dtheta)
		hand_l.position = hand_l.position.rotated(dtheta)
		hand_r.position = hand_r.position.rotated(dtheta)


func punch_attack() -> void:
	if not is_punching and punch_count < number_of_punches:
		is_punching = true
		# punch again
		if punch_with_l:
			var trajectory := player.global_position - hand_l.global_position
			trajectory = trajectory.normalized()\
					* sqrt(minf(punch_range_qdr, trajectory.length_squared()))
			var target = hand_l.global_position + trajectory
			var punch_tween = create_tween()
			punch_tween.tween_property(hand_l, "global_position", target, punch_time)
			punch_tween.parallel().tween_property(hand_l, "scale",\
					normal_hand_l_scale * punch_scale_factor, punch_time)
			punch_tween.finished.connect(punch_return)
		else:
			var trajectory := player.global_position - hand_r.global_position
			trajectory = trajectory.normalized()\
					* sqrt(minf(punch_range_qdr, trajectory.length_squared()))
			var target = hand_r.global_position + trajectory
			var punch_tween = create_tween()
			punch_tween.tween_property(hand_r, "global_position", target, punch_time)
			punch_tween.parallel().tween_property(hand_r, "scale",\
					normal_hand_r_scale * punch_scale_factor, punch_time)
			punch_tween.finished.connect(punch_return)


func punch_return() -> void:
	is_punching = false
	punch_count += 1
	var punch_tween := create_tween()
	if punch_with_l:
		punch_tween.tween_property(hand_l, "position", normal_hand_l_position, punch_return_time)
		punch_tween.parallel().tween_property(hand_l, "scale",\
				normal_hand_l_scale, punch_return_time)
		punch_tween.finished.connect(end_punch)
	else:
		punch_tween.tween_property(hand_r, "position", normal_hand_r_position, punch_return_time)
		punch_tween.parallel().tween_property(hand_r, "scale",\
				normal_hand_r_scale, punch_return_time)
		punch_tween.finished.connect(end_punch)
	punch_with_l = not punch_with_l


func end_punch() -> void:
	if punch_count >= number_of_punches:
		animation_player.play(&"RESET")
		phase = Phase.DELAYING
