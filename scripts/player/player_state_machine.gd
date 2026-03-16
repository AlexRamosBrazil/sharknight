class_name PlayerStateMachine
extends Node

var player: Player
var current_state: PlayerState
var current_state_name := ""
var _states: Dictionary = {}

func setup(state_player: Player) -> void:
	player = state_player
	for child in get_children():
		if child is PlayerState:
			var state := child as PlayerState
			state.setup(player, self)
			_states[child.name.to_lower()] = state

func transition_to(state_name: String, data: Dictionary = {}) -> void:
	var normalized := state_name.to_lower()
	if not _states.has(normalized):
		push_warning("Player state not found: %s" % state_name)
		return
	if current_state_name == normalized:
		return
	if current_state:
		current_state.exit()
	current_state_name = normalized
	current_state = _states[normalized]
	player.on_state_changed(normalized)
	current_state.enter(data)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func post_physics_update(delta: float) -> void:
	if current_state:
		current_state.post_physics_update(delta)

func handle_input() -> void:
	if current_state:
		current_state.handle_input()

func on_combat_action_finished(action_name: String) -> void:
	if current_state:
		current_state.on_combat_action_finished(action_name)

func on_hurt_finished() -> void:
	if current_state:
		current_state.on_hurt_finished()
