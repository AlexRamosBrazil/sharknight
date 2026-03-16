class_name SaveManager
extends Node

const SAVE_PATH := "user://sharknight_save.json"

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_game() -> Dictionary:
	if not save_exists():
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open save file for reading.")
		return {}
	var content: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(content) != OK:
		push_warning("Could not parse save file.")
		return {}
	var data: Variant = json.data
	return data if data is Dictionary else {}

func delete_save() -> void:
	if save_exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
