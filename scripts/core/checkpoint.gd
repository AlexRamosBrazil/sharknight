extends Area2D

@export var active_color := Color(0.2, 0.9, 0.5)
@export var checkpoint_tag := ""
var activated := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if activated or not body.is_in_group("player"):
		return
	var game_state: GameState = body.get_game_state() as GameState
	if game_state:
		var level := get_parent()
		while level and not (level is LevelBase):
			level = level.get_parent()
		var level_path := level.scene_file_path if level else game_state.current_level_path
		game_state.set_checkpoint(global_position, checkpoint_tag, level_path)
	activated = true
	if has_node("Flag"):
		$Flag.color = active_color
