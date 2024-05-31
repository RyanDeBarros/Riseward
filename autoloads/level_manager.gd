extends Node


const LEVEL_paths := [Scenes.SANDBOX_path]


var current_level := 0


func get_win_screen() -> PackedScene:
	if current_level == len(LEVEL_paths) - 1:
		return Scenes.FINAL_WIN_SCREEN
	else:
		return Scenes.WIN_SCREEN


func load_next_level() -> void:
	get_tree().paused = false
	current_level += 1
	get_tree().change_scene_to_file(LEVEL_paths[current_level])


func load_current_level() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_paths[current_level])
