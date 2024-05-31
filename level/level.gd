class_name Level
extends Node2D


var time := 0.0
var enemy_list: Array[Node2D]

@onready var fire_ground: Node2D = %FireGround
@onready var pause_screen: PauseScreen = %PauseScreen
@onready var game_over_screen: GameOverScreen = %GameOverScreen
@onready var win_area: WinArea = %WinArea
@onready var ui_layer: CanvasLayer = %UILayer


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)


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


func _on_player_died() -> void:
	get_tree().paused = true
	game_over_screen.visible = true


func _on_win() -> void:
	get_tree().paused = true
	var win_scene := LevelManager.get_win_screen() as PackedScene
	var win_screen := win_scene.instantiate()
	ui_layer.add_child(win_screen)
