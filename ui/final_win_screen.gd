class_name FinalWinScreen
extends Control


func _ready() -> void:
	AudioManager.play_music("final_win", false)


func _on_menu_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(Scenes.TITLE_SCREEN)
