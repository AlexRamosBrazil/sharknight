extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	if not player.combat.start_ground_combo():
		state_machine.transition_to(player.resolve_ground_state())

func physics_update(_delta: float) -> void:
	player.stop_horizontal()

func handle_input() -> void:
	if player.is_attack_just_pressed() and player.combat.combo_window_open:
		player.combat.queue_combo()

func on_combat_action_finished(action_name: String) -> void:
	if action_name != "attack_ground":
		return
	if player.combat.consume_queued_combo() and player.combat.can_start_melee(player.combat.combo_stamina_cost):
		player.combat.start_ground_combo()
		return
	player.combat.combo_reset_timer.start(0.28)
	state_machine.transition_to(player.resolve_ground_state())
