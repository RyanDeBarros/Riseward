class_name LaunchRamp
extends StaticBody2D


@export var launch_angle := -0.5
@export var launch_magnitude := 5000.0

@onready var launch_impulse := launch_magnitude * Vector2.RIGHT.rotated(launch_angle)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.launch(launch_impulse)
