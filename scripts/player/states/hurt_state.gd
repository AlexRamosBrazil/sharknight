extends PlayerState

func enter(data: Dictionary = {}) -> void:
	var knockback: Vector2 = data.get("knockback", Vector2.ZERO)
	player.combat.stop_block()
	player.velocity = knockback

func physics_update(_delta: float) -> void:
	if player.is_on_floor():
		player.stop_horizontal(player.walk_speed * 0.5)

func on_hurt_finished() -> void:
	if player.is_dead:
		state_machine.transition_to("dead")
		return
	if try_enter_air_mobility_state():
		return
	if player.is_on_floor():
		state_machine.transition_to(player.resolve_ground_state())
	else:
		state_machine.transition_to(player.resolve_air_state())
