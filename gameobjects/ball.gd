class_name Ball
extends RigidBody2D


@export var grab_rotation := 0.0
@export var despawn_time := 22.0

var despawning_tween: Tween

@onready var tile_coin: Sprite2D = $TileCoin
@onready var level := get_tree().get_first_node_in_group(&"level") as Level


func _ready() -> void:
	despawning_tween = create_tween()
	despawning_tween.finished.connect(queue_free)
	despawning_tween.tween_property(tile_coin, "modulate:a", 0, despawn_time)


func _physics_process(_delta: float) -> void:
	if global_position.y > 100:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_overlapping(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_overlapping(self)


func launch(strength: Vector2) -> void:
	apply_central_force(strength * mass)


func pickup() -> void:
	despawning_tween.stop()
	tile_coin.modulate.a = 1.0


func let_go() -> void:
	despawning_tween.play()
