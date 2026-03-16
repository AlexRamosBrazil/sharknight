class_name PlayerMovement
extends Node

@export var enable_double_jump := true
@export var enable_dash := true
@export var enable_wall_slide := true
@export var enable_wall_jump := true
@export var enable_ladder_climb := true
@export var enable_ledge_hang := true
@export var enable_swim := true

@export var dash_duration := 0.16
@export var dash_cooldown := 0.3
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12
@export var wall_slide_speed := 55.0
@export var wall_jump_velocity := Vector2(175, -235)
@export var ladder_speed := 80.0
@export var swim_speed := 72.0
@export var swim_up_velocity := -115.0
@export var ledge_climb_offset := Vector2(10, -22)

var player: Player
var ladder_overlap_count := 0
var water_overlap_count := 0
var dash_available := true
var is_dashing := false
var is_on_ladder := false
var is_swimming := false
var is_hanging_ledge := false
var ledge_direction := 1
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0

@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer

func _ready() -> void:
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)

func setup(owner_player: Player) -> void:
	player = owner_player

func update_frame_state(delta: float) -> void:
	if player == null:
		return
	var on_floor := player.is_on_floor()
	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

func get_move_input() -> float:
	return Input.get_axis("move_left", "move_right")

func get_vertical_input() -> float:
	return Input.get_axis("crouch", "move_up")

func is_run_pressed() -> bool:
	return Input.is_action_pressed("run")

func is_crouch_pressed() -> bool:
	return Input.is_action_pressed("crouch")

func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("jump")

func buffer_jump_input() -> void:
	if is_jump_just_pressed():
		_jump_buffer_timer = jump_buffer_time

func has_buffered_jump() -> bool:
	return _jump_buffer_timer > 0.0

func is_dash_just_pressed() -> bool:
	return Input.is_action_just_pressed("dash")

func is_move_up_pressed() -> bool:
	return Input.is_action_pressed("move_up")

func should_apply_gravity() -> bool:
	return not is_dashing and not is_on_ladder and not is_swimming and not is_hanging_ledge

func should_crouch() -> bool:
	return player.is_on_floor() and is_crouch_pressed() and absf(get_move_input()) < 0.15

func apply_ground_movement(allow_run := true) -> void:
	var direction := get_move_input()
	var speed := player.run_speed if allow_run and is_run_pressed() else player.walk_speed
	player.velocity.x = direction * speed
	player.update_direction_from_input(direction)

func apply_air_movement() -> void:
	var direction := get_move_input()
	player.velocity.x = direction * player.walk_speed
	player.update_direction_from_input(direction)

func apply_swim_movement() -> void:
	var input_vector := Vector2(get_move_input(), -get_vertical_input())
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	player.velocity = input_vector * swim_speed
	player.update_direction_from_input(input_vector.x)

func update_ladder_movement() -> void:
	player.velocity = Vector2(0.0, -get_vertical_input() * ladder_speed)

func stop_horizontal(weight := -1.0) -> void:
	var stop_weight := player.walk_speed if weight < 0.0 else weight
	player.velocity.x = move_toward(player.velocity.x, 0.0, stop_weight)

func stop_all_motion() -> void:
	player.velocity = Vector2.ZERO

func try_start_jump() -> bool:
	if not can_ground_jump():
		return false
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	player.velocity.y = player.jump_velocity
	return true

func try_start_air_jump() -> bool:
	if not enable_double_jump or player.is_on_floor() or player.air_jumps_left <= 0:
		return false
	player.air_jumps_left -= 1
	_jump_buffer_timer = 0.0
	player.velocity.y = player.jump_velocity
	return true

func try_start_dash() -> bool:
	if not enable_dash or not dash_available or is_dashing:
		return false
	is_dashing = true
	dash_available = false
	var direction := player.facing if absf(get_move_input()) < 0.01 else (1 if get_move_input() > 0.0 else -1)
	player.velocity = Vector2(player.dash_speed * float(direction), 0.0)
	dash_timer.start(dash_duration)
	dash_cooldown_timer.start(dash_cooldown)
	return true

func update_dash() -> void:
	player.velocity.y = 0.0

func can_start_ladder() -> bool:
	return enable_ladder_climb and ladder_overlap_count > 0 and absf(get_vertical_input()) > 0.01

func begin_ladder() -> void:
	is_on_ladder = true
	is_swimming = false
	stop_all_motion()

func exit_ladder() -> void:
	is_on_ladder = false

func can_swim_state() -> bool:
	return enable_swim and water_overlap_count > 0

func begin_swim() -> void:
	is_swimming = true
	is_on_ladder = false
	is_hanging_ledge = false
	player.air_jumps_left = player.max_air_jumps

func exit_swim() -> void:
	is_swimming = false

func can_start_wall_slide() -> bool:
	if not enable_wall_slide or player.is_on_floor() or is_dashing or is_swimming or is_on_ladder:
		return false
	if player.velocity.y <= 0.0:
		return false
	return is_touching_wall()

func update_wall_slide() -> void:
	player.velocity.y = minf(player.velocity.y, wall_slide_speed)

func can_wall_jump() -> bool:
	return enable_wall_jump and is_touching_wall()

func start_wall_jump() -> void:
	var jump_dir := -get_wall_direction()
	player.velocity.x = wall_jump_velocity.x * jump_dir
	player.velocity.y = wall_jump_velocity.y
	player.update_direction_from_input(float(jump_dir))

func can_start_ledge_hang() -> bool:
	if not enable_ledge_hang or player.is_on_floor() or is_dashing or is_on_ladder or is_swimming:
		return false
	if player.velocity.y < 0.0:
		return false
	if is_touching_ledge_left():
		ledge_direction = -1
		return true
	if is_touching_ledge_right():
		ledge_direction = 1
		return true
	return false

func begin_ledge_hang() -> void:
	is_hanging_ledge = true
	player.velocity = Vector2.ZERO
	player.update_direction_from_input(float(ledge_direction))

func end_ledge_hang() -> void:
	is_hanging_ledge = false

func climb_ledge() -> void:
	player.global_position += Vector2(ledge_climb_offset.x * ledge_direction, ledge_climb_offset.y)
	end_ledge_hang()

func drop_ledge() -> void:
	end_ledge_hang()
	player.velocity.y = 40.0

func should_reset_air_jumps() -> bool:
	return player.is_on_floor() or is_on_ladder or is_swimming

func can_ground_jump() -> bool:
	if is_on_ladder or is_swimming or is_hanging_ledge:
		return false
	if not has_buffered_jump():
		return false
	return player.is_on_floor() or _coyote_timer > 0.0

func resolve_ground_state() -> String:
	if should_crouch():
		return "crouch"
	if absf(get_move_input()) > 0.01:
		return "run"
	return "idle"

func resolve_air_state() -> String:
	return "jump" if player.velocity.y < 0.0 else "fall"

func enter_ladder_area() -> void:
	ladder_overlap_count += 1

func exit_ladder_area() -> void:
	ladder_overlap_count = maxi(ladder_overlap_count - 1, 0)
	if ladder_overlap_count == 0:
		exit_ladder()

func enter_water_area() -> void:
	water_overlap_count += 1

func exit_water_area() -> void:
	water_overlap_count = maxi(water_overlap_count - 1, 0)
	if water_overlap_count == 0:
		exit_swim()

func is_touching_wall() -> bool:
	return is_touching_left_wall() or is_touching_right_wall()

func get_wall_direction() -> int:
	if is_touching_left_wall():
		return -1
	if is_touching_right_wall():
		return 1
	return player.facing

func is_touching_left_wall() -> bool:
	return player.wall_cast_left.is_colliding()

func is_touching_right_wall() -> bool:
	return player.wall_cast_right.is_colliding()

func is_touching_ledge_left() -> bool:
	return player.ledge_wall_cast_left.is_colliding() and not player.ledge_space_cast_left.is_colliding()

func is_touching_ledge_right() -> bool:
	return player.ledge_wall_cast_right.is_colliding() and not player.ledge_space_cast_right.is_colliding()

func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_dash_cooldown_timeout() -> void:
	dash_available = true
