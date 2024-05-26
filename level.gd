class_name Level
extends Node2D


@export var deathzone_y := 3400


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
