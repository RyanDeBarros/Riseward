class_name TitleScreen
extends Control


func _ready() -> void:
	#AudioManager.play_music("menu")
	pass


func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_packed(Scenes.SANDBOX)


func _on_intro_btn_pressed() -> void:
	pass # Replace with function body.


func _on_tutorial_btn_pressed() -> void:
	pass # Replace with function body.
