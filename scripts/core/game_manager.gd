class_name GameManager
extends Node

signal save_loaded(level_path: String)
signal save_cleared

@export var default_level_path := "res://scenes/levels/coast/Level_CoastKingdom.tscn"

var game_state: GameState
var save_manager: SaveManager

func setup(state: GameState, saver: SaveManager) -> void:
	game_state = state
	save_manager = saver
	game_state.progression_changed.connect(_autosave_progress)

func has_save() -> bool:
	return save_manager != null and save_manager.save_exists()

func new_game() -> String:
	game_state.reset_for_new_game()
	game_state.set_current_level(default_level_path)
	save_progress()
	return default_level_path

func load_or_new_game() -> String:
	if has_save():
		return load_game()
	return new_game()

func load_game() -> String:
	var data := save_manager.load_game()
	if data.is_empty():
		return new_game()
	game_state.apply_save_data(data)
	save_loaded.emit(game_state.current_level_path)
	return game_state.current_level_path

func save_progress() -> void:
	if save_manager == null or game_state == null:
		return
	save_manager.save_game(game_state.to_save_data())

func update_current_level(level_path: String) -> void:
	game_state.set_current_level(level_path)
	save_progress()

func register_checkpoint(level_path: String, checkpoint_tag: String, position: Vector2) -> void:
	game_state.set_checkpoint(position, checkpoint_tag, level_path)
	save_progress()

func unlock_ability(ability_id: String) -> void:
	game_state.unlock_ability(ability_id)
	save_progress()

func clear_save() -> void:
	if save_manager:
		save_manager.delete_save()
	save_cleared.emit()

func _autosave_progress() -> void:
	save_progress()
