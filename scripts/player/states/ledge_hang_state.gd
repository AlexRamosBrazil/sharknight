extends PlayerState

func enter(_data: Dictionary = {}) -> void:
	player.movement.begin_ledge_hang()

func exit() -> void:
	player.movement.end_ledge_hang()

func physics_update(_delta: float) -> void:
	player.movement.stop_all_motion()

func handle_input() -> void:
	if player.is_jump_just_pressed() or player.movement.is_move_up_pressed():
		player.movement.climb_ledge()
		state_machine.transition_to("idle")
		return
	if player.is_crouch_pressed():
		player.movement.drop_ledge()
		state_machine.transition_to("fall")
