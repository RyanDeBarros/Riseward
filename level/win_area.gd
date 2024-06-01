class_name WinArea
extends Area2D


signal win()

@export var level: Level


func _on_body_entered(body: Node2D) -> void:
	if body is Player and len(level.enemy_list) == 0:
		win.emit()
