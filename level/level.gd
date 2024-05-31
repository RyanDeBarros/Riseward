class_name Level
extends Node2D


var time := 0.0

@onready var fire_ground: Node2D = $ParallaxBackground/ParallaxLayer/FireGround
@onready var pause_screen: PauseScreen = $UILayer/PauseScreen


func _ready() -> void:
	pause_screen.unpause.connect(unpause)


func _process(delta: float) -> void:
	time += delta * 3.0
	fire_ground.position.x = 100.0 * sin(time)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		pause_screen.visible = true


func unpause() -> void:
	pause_screen.visible = false
	get_tree().paused = false
