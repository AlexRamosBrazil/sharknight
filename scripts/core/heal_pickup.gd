extends Area2D

@export var heal_amount := 2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var game_state: GameState = body.get_game_state() as GameState
	if game_state == null:
		return
	game_state.heal(heal_amount)
	queue_free()
