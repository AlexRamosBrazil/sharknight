class_name LevelBase
extends Node2D

signal player_spawned(player: Node)
signal level_completed
signal transition_requested(next_level_path: String, spawn_tag: String)

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

@export var default_spawn_tag := "start"
@export_file("*.tscn") var next_level_path := ""
@export var default_spawn_position := Vector2(80, 220)
@export var area_name := "Unnamed Area"

var game_state: GameState
var player: Player

@onready var actors: Node = get_node_or_null("Gameplay/Actors") if has_node("Gameplay/Actors") else get_node_or_null("Actors")
@onready var spawn_points: Node = get_node_or_null("SpawnPoints")

func setup_level(state: GameState) -> void:
	game_state = state
	if scene_file_path != "":
		game_state.set_current_level(scene_file_path)
	game_state.set_area_name(area_name)
	game_state.set_boss_state(false)
	spawn_player(get_spawn_position(default_spawn_tag))

func get_spawn_position(tag: String = default_spawn_tag) -> Vector2:
	if spawn_points:
		if game_state and game_state.has_checkpoint and game_state.checkpoint_tag != "":
			var checkpoint_spawn := spawn_points.get_node_or_null(game_state.checkpoint_tag)
			if checkpoint_spawn is Node2D:
				return checkpoint_spawn.global_position
		var spawn_node := spawn_points.get_node_or_null(tag)
		if spawn_node is Node2D:
			return spawn_node.global_position
	if game_state and game_state.has_checkpoint:
		return game_state.checkpoint_position
	return default_spawn_position

func spawn_player(position: Vector2) -> void:
	if player:
		player.queue_free()
	player = PLAYER_SCENE.instantiate() as Player
	player.global_position = position
	player.game_state = game_state
	if actors == null:
		actors = self
	actors.add_child(player)
	player_spawned.emit(player)

func respawn_player() -> void:
	spawn_player(get_spawn_position(default_spawn_tag))

func complete_level() -> void:
	level_completed.emit()

func request_transition(spawn_tag := "start") -> void:
	if next_level_path == "":
		level_completed.emit()
		return
	transition_requested.emit(next_level_path, spawn_tag)
