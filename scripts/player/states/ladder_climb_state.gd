extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	player.movement.begin_ladder()

func exit() -> void:
	player.movement.exit_ladder()

func physics_update(_delta: float) -> void:
	player.movement.update_ladder_movement()
	if player.is_jump_just_pressed():
		player.movement.exit_ladder()
		player.velocity.y = player.jump_velocity
		state_machine.transition_to("jump")

func post_physics_update(_delta: float) -> void:
	if not player.movement.enable_ladder_climb or player.movement.ladder_overlap_count <= 0:
		state_machine.transition_to(player.resolve_air_state() if not player.is_on_floor() else player.resolve_ground_state())
		return
	if absf(player.movement.get_vertical_input()) <= 0.01 and player.is_on_floor():
		state_machine.transition_to(player.resolve_ground_state())
