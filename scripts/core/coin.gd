extends Area2D

@export var value: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var game_state: GameState = body.get_game_state() as GameState
	if game_state:
		game_state.add_coin(value)
	queue_free()
