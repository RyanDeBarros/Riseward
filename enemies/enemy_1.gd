class_name Enemy1
extends RigidBody2D


enum Attacks {
	SPIN_C,
	SPIN_CC,
	PUNCH
}

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
@export var reposte_susceptibility := 10.0
@export var face_max_x := 20.0

@export_group("Attack")
@export var attack_delay_min := 0.5
@export var attack_delay_max := 3.0
@export_group("Spin")
@export var spin_range_qdr := 750.0 ** 2
@export var angular_speed := 10.0
@export var total_spin_radians := 5 * PI
@export_group("Punch")
@export var punch_range_qdr := 2000.0 ** 2

var attack_delay := 0.0
var phase := Phase.CHILLING
var total_spin := 0.0

@onready var level := get_tree().get_first_node_in_group(&"level") as Level
@onready var face: Node2D = $Face
@onready var hand_l: Node2D = $HandL
@onready var hand_r: Node2D = $HandR
@onready var hit_area_l: Area2D = $HandL/HitAreaL
@onready var hit_area_r: Area2D = $HandR/HitAreaR
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player := get_tree().get_first_node_in_group(&"player") as Player


func _process(delta: float) -> void:
	look_at_player()
	if phase == Phase.CHILLING:
		var quadrance := (player.global_position - global_position).length_squared()
		if quadrance <= spin_range_qdr:
			init_spin_attack()
		elif quadrance <= punch_range_qdr:
			init_punch_attack()
	elif phase == Phase.SPINNING_C:
		spin_attack(delta, true)
	elif phase == Phase.SPINNING_CC:
		spin_attack(delta, false)
	elif phase == Phase.PUNCHING:
		punch_attack(delta)
	elif phase == Phase.DELAYING:
		attack_delay -= delta
		if attack_delay <= 0.0:
			phase = Phase.CHILLING


func _on_hit_area_l_body_entered(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - hit_area_l.global_position).normalized()
		attack_hits(direction)


func _on_hit_area_l_body_exited(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - hit_area_l.global_position).normalized()
		attack_hits(direction)


func _on_hit_area_r_body_entered(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - hit_area_r.global_position).normalized()
		attack_hits(direction)


func _on_hit_area_r_body_exited(body: Node2D) -> void:
	if body is Player:
		var direction := (body.global_position - hit_area_r.global_position).normalized()
		attack_hits(direction)


func attack_hits(direction: Vector2) -> void:
	var reposte := player.bounce_back(direction * hit_strength, 1.2) as Vector2
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


func punch_attack(delta: float) -> void:
	await get_tree().create_timer(1.0).timeout
	animation_player.play(&"RESET")
	phase = Phase.DELAYING
