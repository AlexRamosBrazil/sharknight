class_name PlayerState
extends Node

var player: Player
var state_machine: PlayerStateMachine

func setup(state_player: Player, machine: PlayerStateMachine) -> void:
	player = state_player
	state_machine = machine

func enter(_data: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func post_physics_update(_delta: float) -> void:
	pass

func handle_input() -> void:
	pass

func on_combat_action_finished(_action_name: String) -> void:
	pass

func on_hurt_finished() -> void:
	pass

func try_enter_ground_mobility_state() -> bool:
	if player.movement.can_swim_state() and not player.is_on_floor():
		state_machine.transition_to("swim")
		return true
	if player.movement.can_start_ladder():
		state_machine.transition_to("ladder_climb")
		return true
	if player.movement.is_dash_just_pressed() and player.movement.try_start_dash():
		state_machine.transition_to("dash")
		return true
	return false

func try_enter_air_mobility_state() -> bool:
	if player.movement.can_swim_state():
		state_machine.transition_to("swim")
		return true
	if player.movement.can_start_ladder():
		state_machine.transition_to("ladder_climb")
		return true
	if player.movement.can_start_ledge_hang():
		state_machine.transition_to("ledge_hang")
		return true
	if player.movement.can_start_wall_slide():
		state_machine.transition_to("wall_slide")
		return true
	if player.movement.is_dash_just_pressed() and player.movement.try_start_dash():
		state_machine.transition_to("dash")
		return true
	return false
