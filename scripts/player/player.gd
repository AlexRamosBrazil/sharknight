class_name Player
extends CharacterBody2D

signal facing_changed(direction: int)
signal state_changed(state_name: String)
signal combat_action_started(action_name: String)
signal combat_action_finished(action_name: String)
signal mobility_state_changed(state_name: String)

@export var walk_speed := 85.0
@export var run_speed := 135.0
@export var jump_velocity := -350.0
@export var gravity := 980.0
@export var invincibility_time := 0.7
@export var contact_damage_knockback := Vector2(180, -180)
@export var max_combo_step := 3
@export var max_air_jumps := 1
@export var dash_speed := 220.0

var game_state: GameState
var facing := 1
var invincible := false
var is_dead := false
var air_jumps_left := 0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var shield_sprite: Sprite2D = $ShieldSprite
@onready var hurt_timer: Timer = $HurtTimer
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var movement: PlayerMovement = $Movement
@onready var combat: PlayerCombat = $Combat
@onready var wall_cast_left: RayCast2D = $WallCastLeft
@onready var wall_cast_right: RayCast2D = $WallCastRight
@onready var ledge_wall_cast_left: RayCast2D = $LedgeWallCastLeft
@onready var ledge_space_cast_left: RayCast2D = $LedgeSpaceCastLeft
@onready var ledge_wall_cast_right: RayCast2D = $LedgeWallCastRight
@onready var ledge_space_cast_right: RayCast2D = $LedgeSpaceCastRight

func _ready() -> void:
	add_to_group("player")
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	combat.action_started.connect(_on_combat_action_started)
	combat.action_finished.connect(_on_combat_action_finished)
	if game_state and not game_state.progression_changed.is_connected(_apply_unlocked_abilities):
		game_state.progression_changed.connect(_apply_unlocked_abilities)
	air_jumps_left = max_air_jumps
	_apply_placeholder_visual(body_sprite, Vector2i(12, 20), Color(0.55, 0.84, 0.79))
	_apply_placeholder_visual(shield_sprite, Vector2i(8, 12), Color(0.62, 0.81, 0.51))
	_update_facing()
	movement.setup(self)
	combat.setup(self)
	_apply_unlocked_abilities()
	state_machine.setup(self)
	state_machine.transition_to("idle")

func _physics_process(delta: float) -> void:
	movement.buffer_jump_input()
	movement.update_frame_state(delta)
	if movement.should_apply_gravity() and not is_on_floor():
		velocity.y += gravity * delta
	if movement.should_reset_air_jumps():
		air_jumps_left = max_air_jumps

	state_machine.handle_input()
	state_machine.physics_update(delta)
	move_and_slide()
	state_machine.post_physics_update(delta)
	combat.spend_block_stamina(delta)
	_refresh_invincibility_feedback()
	_restore_resources(delta)

func on_state_changed(next_state: String) -> void:
	state_changed.emit(next_state)
	mobility_state_changed.emit(next_state)

func get_move_input() -> float:
	return movement.get_move_input()

func is_run_pressed() -> bool:
	return movement.is_run_pressed()

func is_crouch_pressed() -> bool:
	return movement.is_crouch_pressed()

func is_jump_just_pressed() -> bool:
	return movement.is_jump_just_pressed()

func is_attack_just_pressed() -> bool:
	return combat.is_attack_just_pressed()

func is_charge_just_pressed() -> bool:
	return combat.is_charge_just_pressed()

func is_ranged_just_pressed() -> bool:
	return combat.is_ranged_just_pressed()

func is_special_just_pressed() -> bool:
	return combat.is_special_just_pressed()

func is_block_pressed() -> bool:
	return combat.is_block_pressed()

func should_crouch() -> bool:
	return movement.should_crouch()

func apply_ground_movement(allow_run := true) -> void:
	movement.apply_ground_movement(allow_run)

func apply_air_movement() -> void:
	movement.apply_air_movement()

func stop_horizontal(weight := -1.0) -> void:
	movement.stop_horizontal(weight)

func try_start_jump() -> bool:
	return movement.try_start_jump()

func try_start_air_jump() -> bool:
	return movement.try_start_air_jump()

func resolve_ground_state() -> String:
	return movement.resolve_ground_state()

func resolve_air_state() -> String:
	return movement.resolve_air_state()

func update_direction_from_input(direction: float) -> void:
	if absf(direction) <= 0.01:
		return
	facing = 1 if direction > 0.0 else -1
	_update_facing()

func is_blocking() -> bool:
	return combat.is_blocking()

func is_dashing() -> bool:
	return movement.is_dashing

func is_on_ladder() -> bool:
	return movement.is_on_ladder

func is_swimming() -> bool:
	return movement.is_swimming

func is_hanging_ledge() -> bool:
	return movement.is_hanging_ledge

func enter_ladder_area() -> void:
	movement.enter_ladder_area()

func exit_ladder_area() -> void:
	movement.exit_ladder_area()

func enter_water_area() -> void:
	movement.enter_water_area()

func exit_water_area() -> void:
	movement.exit_water_area()

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if invincible or is_dead or game_state == null:
		return
	var applied_knockback := knockback
	if applied_knockback == Vector2.ZERO:
		applied_knockback = Vector2(contact_damage_knockback.x * -facing, contact_damage_knockback.y)
	if combat.can_block_hit(applied_knockback):
		if not game_state.use_stamina(8.0):
			game_state.damage(amount)
			if game_state.health <= 0:
				is_dead = true
				velocity = applied_knockback
				state_machine.transition_to("dead", {"knockback": applied_knockback})
				return
			begin_invincibility()
			state_machine.transition_to("hurt", {"knockback": applied_knockback})
			return
		velocity = Vector2(-applied_knockback.x * 0.25, applied_knockback.y * 0.25)
		return
	game_state.damage(amount)
	if game_state.health <= 0:
		is_dead = true
		velocity = applied_knockback
		state_machine.transition_to("dead", {"knockback": applied_knockback})
		return
	begin_invincibility()
	state_machine.transition_to("hurt", {"knockback": applied_knockback})

func begin_invincibility() -> void:
	invincible = true
	hurt_timer.start(invincibility_time)

func end_invincibility() -> void:
	invincible = false
	modulate.a = 1.0

func get_game_state() -> GameState:
	return game_state

func _apply_unlocked_abilities() -> void:
	if game_state == null:
		return
	movement.enable_double_jump = game_state.has_ability("double_jump")
	movement.enable_dash = game_state.has_ability("dash")
	movement.enable_wall_slide = game_state.has_ability("wall_slide")
	movement.enable_wall_jump = game_state.has_ability("wall_jump")
	movement.enable_ledge_hang = game_state.has_ability("ledge_hang")
	movement.enable_swim = game_state.has_ability("swim")
	movement.enable_ladder_climb = game_state.has_ability("ladder_climb")

func _restore_resources(delta: float) -> void:
	if game_state == null:
		return
	if not combat.is_busy() and not combat.is_blocking() and not is_dead:
		game_state.restore_stamina(delta * 12.0)
	game_state.restore_magic(delta * 4.0)

func _refresh_invincibility_feedback() -> void:
	if invincible:
		modulate.a = 0.65 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0

func _update_facing() -> void:
	body_sprite.flip_h = facing < 0
	shield_sprite.flip_h = facing < 0
	combat.scale.x = facing
	facing_changed.emit(facing)

func _apply_placeholder_visual(sprite: Sprite2D, size: Vector2i, color: Color) -> void:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true

func _on_hurt_timer_timeout() -> void:
	end_invincibility()
	state_machine.on_hurt_finished()

func _on_combat_action_started(action_name: String) -> void:
	combat_action_started.emit(action_name)

func _on_combat_action_finished(action_name: String) -> void:
	combat_action_finished.emit(action_name)
	state_machine.on_combat_action_finished(action_name)
