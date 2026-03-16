extends Control

signal resume_requested
signal restart_requested
signal main_menu_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$CenterContainer/Frame/VBoxContainer/ResumeButton.pressed.connect(func() -> void: resume_requested.emit())
	$CenterContainer/Frame/VBoxContainer/RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	$CenterContainer/Frame/VBoxContainer/MainMenuButton.pressed.connect(func() -> void: main_menu_requested.emit())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()
