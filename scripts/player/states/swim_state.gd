extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	player.movement.begin_swim()

func exit() -> void:
	player.movement.exit_swim()

func physics_update(_delta: float) -> void:
	player.movement.apply_swim_movement()
	if player.is_jump_just_pressed():
		player.velocity.y = player.movement.swim_up_velocity

func handle_input() -> void:
	if player.is_attack_just_pressed() and player.combat.can_start_melee(player.combat.air_stamina_cost):
		state_machine.transition_to("attack_air")

func post_physics_update(_delta: float) -> void:
	if not player.movement.can_swim_state():
		if player.is_on_floor():
			state_machine.transition_to(player.resolve_ground_state())
		else:
			state_machine.transition_to(player.resolve_air_state())
		return
	if player.movement.can_start_ladder():
		state_machine.transition_to("ladder_climb")
