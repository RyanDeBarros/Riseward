class_name ItemBox
extends Area2D


const num_spawn_sits := 3
enum SpawnSit {
	ONE_BALL,
	TWO_BALLS,
	ONE_BAT
}

@export var cooldown_speed_mult := 0.15
@export var initial_velocity := 300.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var spawn_single: Marker2D = $SpawnSingle
@onready var spawn_double_1: Marker2D = $SpawnDouble1
@onready var spawn_double_2: Marker2D = $SpawnDouble2


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_overlapping(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_overlapping(self)


func pop() -> void:
	collision_shape_2d.disabled = true
	spawn_items()
	animation_player.play(&"pop")
	await animation_player.animation_finished
	animation_player.play(&"cooldown", -1, cooldown_speed_mult)
	await animation_player.animation_finished
	collision_shape_2d.disabled = false


func spawn_items() -> void:
	var dir := get_tree().get_first_node_in_group(&"items_dir") as Node2D
	var sit := SpawnSit.values()[randi_range(0, num_spawn_sits - 1)] as SpawnSit
	if sit == SpawnSit.ONE_BALL:
		var ball := Scenes.BALL.instantiate() as Ball
		dir.add_child(ball)
		ball.global_position = spawn_single.global_position
		ball.linear_velocity = Vector2.UP * initial_velocity
	elif sit == SpawnSit.TWO_BALLS:
		var ball1 := Scenes.BALL.instantiate() as Ball
		var ball2 := Scenes.BALL.instantiate() as Ball
		dir.add_child(ball1)
		dir.add_child(ball2)
		ball1.global_position = spawn_double_1.global_position
		ball2.global_position = spawn_double_2.global_position
		ball1.linear_velocity = Vector2.UP * initial_velocity
		ball2.linear_velocity = Vector2.UP * initial_velocity
	elif sit == SpawnSit.ONE_BAT:
		var bat := Scenes.BAT.instantiate() as Bat
		dir.add_child(bat)
		bat.global_position = spawn_single.global_position
		bat.linear_velocity = Vector2.UP * initial_velocity
