class_name LaunchRamp
extends StaticBody2D


@export var launch_angle := -0.4
@export var launch_magnitude := 6000.0

@onready var launch_direction := Vector2.RIGHT.rotated(launch_angle)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.launch(launch_direction, launch_magnitude)
