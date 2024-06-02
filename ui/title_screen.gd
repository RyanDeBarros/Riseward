class_name TitleScreen
extends Control


func _ready() -> void:
	AudioManager.play_music("menu")
	pass


func _on_intro_btn_pressed() -> void:
	get_tree().change_scene_to_packed(Scenes.INTRO)


func _on_tutorial_btn_pressed() -> void:
	get_tree().change_scene_to_packed(Scenes.TUTORIAL)


func _on_continue_btn_pressed() -> void:
	play()


func _on_begin_new_btn_pressed() -> void:
	LevelManager.reset()
	play()


func play() -> void:
	AudioManager.play_music("level")
	LevelManager.load_current_level()
