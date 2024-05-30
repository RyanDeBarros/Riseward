class_name Bat
extends RigidBody2D


@export var grab_rotation := -2.0
@export var strength := 5000.0
@export var despawn_time := 22.0

var owning_player: Player
var despawning_tween: Tween

@onready var baseball_bat: Sprite2D = $BaseballBat
@onready var impact_collision: CollisionShape2D = $HitArea/ImpactCollision
@onready var level := get_tree().get_first_node_in_group(&"level") as Level


func _ready() -> void:
	despawning_tween = create_tween()
	despawning_tween.finished.connect(queue_free)
	despawning_tween.tween_property(baseball_bat, "modulate:a", 0, despawn_time)


func _physics_process(_delta: float) -> void:
	if global_position.y > 100:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_overlapping(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_overlapping(self)


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"enemy") and owning_player:
		var launch_dir := (body.global_position - owning_player.global_position).normalized()
		(body as RigidBody2D).apply_central_impulse(strength * launch_dir)


func is_attacking(player: Player) -> void:
	impact_collision.disabled = (player == null)
	owning_player = player


func pickup() -> void:
	despawning_tween.stop()
	baseball_bat.modulate.a = 1.0


func let_go() -> void:
	despawning_tween.play()
