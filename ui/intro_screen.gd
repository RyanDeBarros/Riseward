class_name IntroScreen
extends Control


func _on_menu_btn_pressed() -> void:
	get_tree().change_scene_to_packed(Scenes.TITLE_SCREEN)
