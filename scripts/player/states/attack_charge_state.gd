extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	if not player.combat.start_charge_attack():
		state_machine.transition_to(player.resolve_ground_state())

func physics_update(_delta: float) -> void:
	player.stop_horizontal()

func on_combat_action_finished(action_name: String) -> void:
	if action_name == "attack_charge":
		player.combat.reset_combo()
		state_machine.transition_to(player.resolve_ground_state())
