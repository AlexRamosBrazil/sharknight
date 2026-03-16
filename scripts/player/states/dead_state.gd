extends PlayerState

func enter(data: Dictionary = {}) -> void:
	var knockback: Vector2 = data.get("knockback", Vector2.ZERO)
	player.combat.stop_block()
	player.combat.cancel_actions()
	player.velocity = knockback

func physics_update(_delta: float) -> void:
	player.stop_horizontal(player.walk_speed * 0.35)
