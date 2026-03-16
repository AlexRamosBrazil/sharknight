extends Control

signal new_game_requested
signal continue_requested
signal quit_requested

func _ready() -> void:
	$CenterContainer/PanelContainer/VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func set_continue_enabled(enabled: bool) -> void:
	$CenterContainer/PanelContainer/VBoxContainer/ContinueButton.visible = enabled
	$CenterContainer/PanelContainer/VBoxContainer/ContinueButton.disabled = not enabled

func _on_continue_pressed() -> void:
	continue_requested.emit()

func _on_new_game_pressed() -> void:
	new_game_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
