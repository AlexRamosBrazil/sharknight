extends Control

signal restart_requested
signal main_menu_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$CenterContainer/Frame/VBoxContainer/RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	$CenterContainer/Frame/VBoxContainer/MainMenuButton.pressed.connect(func() -> void: main_menu_requested.emit())
