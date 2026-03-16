extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	if not player.combat.start_ranged_attack():
		state_machine.transition_to(player.resolve_ground_state() if player.is_on_floor() else player.resolve_air_state())

func physics_update(_delta: float) -> void:
	if player.is_on_floor():
		player.stop_horizontal()
	else:
		player.apply_air_movement()

func on_combat_action_finished(action_name: String) -> void:
	if action_name == "attack_ranged":
		state_machine.transition_to(player.resolve_ground_state() if player.is_on_floor() else player.resolve_air_state())
