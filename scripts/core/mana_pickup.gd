extends Area2D

@export var mana_amount := 15.0
@export var projectile_amount := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var game_state: GameState = body.get_game_state() as GameState
	if game_state == null:
		return
	game_state.restore_magic(mana_amount)
	if projectile_amount > 0:
		game_state.refill_projectiles(projectile_amount)
	queue_free()
