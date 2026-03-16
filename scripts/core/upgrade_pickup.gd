extends Area2D

@export_enum("max_health", "max_magic", "ability") var upgrade_type := "max_health"
@export var amount := 1
@export var ability_id := "double_jump"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var game_state: GameState = body.get_game_state() as GameState
	if game_state == null:
		return
	match upgrade_type:
		"max_health":
			game_state.increase_max_health(amount)
		"max_magic":
			game_state.increase_max_magic(float(amount))
		"ability":
			game_state.unlock_ability(ability_id)
	queue_free()
