class_name Platform
extends RigidBody2D


enum Phase {
	WAITING,
	SHAKING,
	DROPPING
}

@export var enemy_detect: Area2D

@export_group("Dropping & Shaking")
@export var drop_countdown_time := 5.0
@export var shake_countdown_time := 3.0
@export var shake_speed := 40.0
@export var shake_amplitude := 20.0
@export var drop_speed := 500.0

var drop_timer: Timer
var phase := Phase.WAITING
var shake_t := 0.0
var initial_x := 0.0

@onready var level := get_tree().get_first_node_in_group(&"level") as Level


func _ready() -> void:
	drop_timer = Timer.new()
	add_child(drop_timer)
	drop_timer.timeout.connect(begin_shake)
	drop_timer.one_shot = true
	drop_timer.wait_time = drop_countdown_time


func _physics_process(delta: float) -> void:
	if phase == Phase.WAITING:
		for body in enemy_detect.get_overlapping_bodies():
			if body.is_in_group(&"enemy"):
				cancel_drop_timer()
				return
		init_drop_timer()
	elif phase == Phase.SHAKING:
		shake_x(delta)
	elif phase == Phase.DROPPING:
		shake_x(delta)
		position.y += drop_speed * delta
		if position.y > level.deathzone_y:
			queue_free()


func init_drop_timer() -> void:
	if drop_timer.is_stopped():
		drop_timer.start()


func cancel_drop_timer() -> void:
	drop_timer.stop()


func begin_shake() -> void:
	phase = Phase.SHAKING
	drop_timer.wait_time = shake_countdown_time
	drop_timer.timeout.disconnect(begin_shake)
	drop_timer.timeout.connect(begin_drop)
	drop_timer.start()
	initial_x = position.x


func begin_drop() -> void:
	phase = Phase.DROPPING


func shake_x(delta: float) -> void:
	shake_t += delta
	position.x = initial_x + shake_amplitude * sin(shake_speed * shake_t)
