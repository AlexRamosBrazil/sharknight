extends PlayerState

func physics_update(_delta: float) -> void:
	player.apply_air_movement()

func post_physics_update(_delta: float) -> void:
	if try_enter_air_mobility_state():
		return
	if player.is_on_floor():
		state_machine.transition_to(player.resolve_ground_state())
		return
	if player.velocity.y >= 0.0:
		state_machine.transition_to("fall")

func handle_input() -> void:
	if player.is_jump_just_pressed() and player.try_start_air_jump():
		return
	if try_enter_air_mobility_state():
		return
	if player.is_ranged_just_pressed() and player.combat.can_start_ranged():
		state_machine.transition_to("attack_ranged")
		return
	if player.is_attack_just_pressed() and player.combat.can_start_melee(player.combat.air_stamina_cost):
		state_machine.transition_to("attack_air")
