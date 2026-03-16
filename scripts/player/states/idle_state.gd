extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	player.stop_horizontal()

func physics_update(_delta: float) -> void:
	player.stop_horizontal()
	if player.try_start_jump():
		state_machine.transition_to("jump")
		return
	if not player.is_on_floor():
		state_machine.transition_to(player.resolve_air_state())
		return
	if player.should_crouch():
		state_machine.transition_to("crouch")
		return
	if absf(player.get_move_input()) > 0.01:
		state_machine.transition_to("run")

func handle_input() -> void:
	if try_enter_ground_mobility_state():
		return
	if player.is_block_pressed() and player.combat.can_block():
		state_machine.transition_to("block")
		return
	if player.is_special_just_pressed() and player.combat.can_start_special():
		state_machine.transition_to("attack_special")
		return
	if player.is_ranged_just_pressed() and player.combat.can_start_ranged():
		state_machine.transition_to("attack_ranged")
		return
	if player.is_charge_just_pressed() and player.combat.can_start_charge():
		state_machine.transition_to("attack_charge")
		return
	if player.is_attack_just_pressed() and player.combat.can_start_melee(player.combat.combo_stamina_cost):
		state_machine.transition_to("attack_ground")
