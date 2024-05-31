class_name PauseScreen
extends Control


signal unpause()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		unpause.emit()


func _on_resume_btn_pressed() -> void:
	unpause.emit()


func _on_menu_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(Scenes.TITLE_SCREEN)
