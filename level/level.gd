class_name Level
extends Node2D


var time := 0.0

@onready var fire_ground: Node2D = $ParallaxBackground/ParallaxLayer/FireGround


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
	#AudioManager.play_music("level")


func _process(delta: float) -> void:
	time += delta * 3.0
	fire_ground.position.x = 100.0 * sin(time)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
