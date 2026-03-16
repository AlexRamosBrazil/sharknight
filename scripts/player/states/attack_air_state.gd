extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	if not player.combat.start_air_attack():
		state_machine.transition_to(player.resolve_air_state())

func physics_update(_delta: float) -> void:
	player.apply_air_movement()

func post_physics_update(_delta: float) -> void:
	if player.is_on_floor() and not player.combat.is_busy():
		state_machine.transition_to(player.resolve_ground_state())

func on_combat_action_finished(action_name: String) -> void:
	if action_name == "attack_air":
		player.combat.reset_combo()
		state_machine.transition_to(player.resolve_air_state())
