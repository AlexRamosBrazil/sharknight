extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	player.combat.start_block()
	player.stop_horizontal()

func exit() -> void:
	player.combat.stop_block()

func physics_update(_delta: float) -> void:
	player.stop_horizontal()
	if not player.is_on_floor():
		state_machine.transition_to(player.resolve_air_state())
		return
	if not player.is_block_pressed() or not player.combat.can_block():
		state_machine.transition_to(player.resolve_ground_state())
