class_name WinScreen
extends Control


func _ready() -> void:
	AudioManager.play_music("win", false)


func _on_resume_btn_pressed() -> void:
	LevelManager.load_next_level()


func _on_menu_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(Scenes.TITLE_SCREEN)
