class_name Platform
extends Node


@export var waypoint_1: Marker2D
@export var waypoint_2: Marker2D
@export var landing_target: Marker2D


class WaypointSession:
	var current_target: Vector2
	var other_target: Vector2
	var current_position: Vector2
	var threshold: float
	
	func _init(platform: Platform, first_wp_first := true, threshold_qdr := 2.0) -> void:
		if first_wp_first:
			current_target = platform.waypoint_1.global_position
		else:
			current_target = platform.waypoint_2.global_position
		threshold = threshold_qdr
	
	func next_dir(position: Vector2, speed: float) -> Vector2:
		
		
		
		
		
		
		
		
		
		var offset := position - current_position
		var delta := (current_target - current_position) * speed
		if abs(delta.length_squared()) < threshold:
			var temp := current_target
			current_target = other_target
			other_target = temp
		
		current_position += delta
		return current_position + offset
