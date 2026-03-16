extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	if not player.is_dashing():
		state_machine.transition_to(player.resolve_ground_state() if player.is_on_floor() else player.resolve_air_state())

func physics_update(_delta: float) -> void:
	player.movement.update_dash()

func post_physics_update(_delta: float) -> void:
	if not player.is_dashing():
		if player.is_on_floor():
			state_machine.transition_to(player.resolve_ground_state())
		else:
			state_machine.transition_to(player.resolve_air_state())
