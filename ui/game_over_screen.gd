class_name GameOverScreen
extends Control


func _on_menu_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(Scenes.TITLE_SCREEN)


func _on_retry_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(Scenes.SANDBOX_path)
