extends Node

const MAIN_MENU_SCENE := preload("res://scenes/ui/MainMenu.tscn")
const LEVEL_SCENE := preload("res://scenes/levels/coast/Level_CoastKingdom.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/PauseMenu.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/GameOverScreen.tscn")
const VICTORY_SCENE := preload("res://scenes/ui/VictoryScreen.tscn")

@onready var game_state: GameState = $GameState
@onready var save_manager: SaveManager = $SaveManager
@onready var game_manager: GameManager = $GameManager
@onready var scene_root: Node = $SceneRoot
@onready var ui_root: CanvasLayer = $UIRoot

var current_scene: Node
var hud: CanvasLayer
var pause_menu: Control
var game_over_screen: Control
var victory_screen: Control

func _ready() -> void:
	game_manager.setup(game_state, save_manager)
	game_state.player_died.connect(_on_player_died)
	_load_ui()
	show_main_menu()

func _load_ui() -> void:
	hud = HUD_SCENE.instantiate()
	ui_root.add_child(hud)
	hud.bind_game_state(game_state)
	hud.visible = false
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	ui_root.add_child(pause_menu)
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.restart_requested.connect(restart_level)
	pause_menu.main_menu_requested.connect(_return_to_main_menu)
	game_over_screen = GAME_OVER_SCENE.instantiate()
	ui_root.add_child(game_over_screen)
	game_over_screen.restart_requested.connect(restart_level)
	game_over_screen.main_menu_requested.connect(_return_to_main_menu)
	victory_screen = VICTORY_SCENE.instantiate()
	ui_root.add_child(victory_screen)
	victory_screen.continue_requested.connect(_on_victory_continue)
	victory_screen.main_menu_requested.connect(_return_to_main_menu)

func show_main_menu() -> void:
	_close_overlays()
	_replace_scene(MAIN_MENU_SCENE.instantiate())
	hud.visible = false
	current_scene.set_continue_enabled(game_manager.has_save())
	current_scene.continue_requested.connect(continue_game)
	current_scene.new_game_requested.connect(start_new_game)
	current_scene.quit_requested.connect(_quit_game)

func start_new_game() -> void:
	get_tree().paused = false
	_load_level(game_manager.new_game())

func continue_game() -> void:
	get_tree().paused = false
	_load_level(game_manager.load_game())

func restart_level() -> void:
	get_tree().paused = false
	_close_overlays()
	_load_level(game_manager.load_game())

func _load_level(level_path := LEVEL_SCENE.resource_path) -> void:
	_close_overlays()
	var level_scene := load(level_path) as PackedScene
	if level_scene == null:
		level_scene = LEVEL_SCENE
		level_path = LEVEL_SCENE.resource_path
	game_manager.update_current_level(level_path)
	_replace_scene(level_scene.instantiate())
	hud.visible = true
	current_scene.level_completed.connect(_on_level_completed)
	current_scene.player_spawned.connect(_bind_player)
	if current_scene.has_signal("transition_requested"):
		current_scene.transition_requested.connect(_on_level_transition_requested)
	current_scene.setup_level(game_state)

func _bind_player(player: Node) -> void:
	hud.bind_player(player)

func _replace_scene(next_scene: Node) -> void:
	if current_scene:
		current_scene.queue_free()
	current_scene = next_scene
	scene_root.add_child(current_scene)

func _on_player_died() -> void:
	get_tree().paused = true
	game_over_screen.visible = true
	hud.visible = false

func _on_level_completed() -> void:
	get_tree().paused = true
	hud.visible = false
	victory_screen.visible = true
	victory_screen.set_summary(game_state.current_area_name, game_state.coins)

func _unhandled_input(event: InputEvent) -> void:
	if current_scene == null or current_scene is Control:
		return
	if event.is_action_pressed("ui_cancel") and not game_over_screen.visible and not victory_screen.visible:
		get_viewport().set_input_as_handled()
		if pause_menu.visible:
			_resume_game()
		else:
			_pause_game()

func _pause_game() -> void:
	get_tree().paused = true
	pause_menu.visible = true

func _resume_game() -> void:
	pause_menu.visible = false
	get_tree().paused = false

func _return_to_main_menu() -> void:
	get_tree().paused = false
	_close_overlays()
	show_main_menu()

func _on_victory_continue() -> void:
	get_tree().paused = false
	_close_overlays()
	show_main_menu()

func _on_level_transition_requested(next_level_path: String, spawn_tag: String) -> void:
	game_state.checkpoint_tag = spawn_tag
	game_state.has_checkpoint = false
	_load_level(next_level_path)

func _close_overlays() -> void:
	pause_menu.visible = false
	game_over_screen.visible = false
	victory_screen.visible = false
	hud.visible = current_scene != null and not (current_scene is Control)

func _quit_game() -> void:
	get_tree().quit()
