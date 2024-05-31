class_name TutorialScreen
extends Control


@export var pages: Array[Control]

@onready var next_btn: Button = $NextBTN
@onready var current_page := 0


func _on_menu_btn_pressed() -> void:
	get_tree().change_scene_to_packed(Scenes.TITLE_SCREEN)


func _on_next_btn_pressed() -> void:
	current_page += 1
	if current_page < len(pages):
		pages[current_page - 1].visible = false
		pages[current_page].visible = true
		if current_page == len(pages) - 1:
			next_btn.visible = false
	else:
		get_tree().change_scene_to_packed(Scenes.TITLE_SCREEN)
