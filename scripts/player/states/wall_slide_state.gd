extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	player.combat.stop_block()

func physics_update(_delta: float) -> void:
	player.movement.update_wall_slide()
	player.apply_air_movement()
	if player.is_jump_just_pressed() and player.movement.can_wall_jump():
		player.movement.start_wall_jump()
		state_machine.transition_to("jump")

func post_physics_update(_delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to(player.resolve_ground_state())
		return
	if not player.movement.can_start_wall_slide():
		state_machine.transition_to(player.resolve_air_state())
