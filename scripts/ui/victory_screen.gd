extends Control

signal continue_requested
signal main_menu_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$CenterContainer/Frame/VBoxContainer/ContinueButton.pressed.connect(func() -> void: continue_requested.emit())
	$CenterContainer/Frame/VBoxContainer/MainMenuButton.pressed.connect(func() -> void: main_menu_requested.emit())

func set_summary(area_name: String, coins: int) -> void:
	$CenterContainer/Frame/VBoxContainer/Subtitle.text = "Area concluida: %s" % area_name
	$CenterContainer/Frame/VBoxContainer/SummaryLabel.text = "Moedas coletadas: %d" % coins
