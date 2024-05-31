class_name Level
extends Node2D


var time := 0.0

@onready var fire_ground: Node2D = $ParallaxBackground/ParallaxLayer/FireGround


func _ready() -> void:
	#AudioManager.play_music("level")
	pass


func _process(delta: float) -> void:
	time += delta * 3.0
	fire_ground.position.x = 100.0 * sin(time)
