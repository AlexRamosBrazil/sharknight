class_name PlayerCombat
extends Node2D

signal action_started(action_name: String)
signal action_finished(action_name: String)
signal projectile_fired(projectile: Projectile)
signal block_started
signal block_ended

const PROJECTILE_SCENE := preload("res://scenes/combat/PlayerProjectile.tscn")

@export var combo_stamina_cost := 15.0
@export var crouch_stamina_cost := 12.0
@export var air_stamina_cost := 14.0
@export var charged_stamina_cost := 28.0
@export var ranged_stamina_cost := 8.0
@export var special_stamina_cost := 25.0
@export var special_magic_cost := 20.0
@export var block_stamina_drain := 8.0
@export var ranged_cooldown := 0.45
@export var charge_cooldown := 0.85
@export var special_cooldown := 1.4

var player: Player
var current_action := ""
var combo_step := 0
var combo_window_open := false
var queued_combo := false
var blocking := false

@onready var ground_hitbox: AttackHitbox = $Hitboxes/GroundHitbox
@onready var crouch_hitbox: AttackHitbox = $Hitboxes/CrouchHitbox
@onready var air_hitbox: AttackHitbox = $Hitboxes/AirHitbox
@onready var charge_hitbox: AttackHitbox = $Hitboxes/ChargeHitbox
@onready var special_hitbox: AttackHitbox = $Hitboxes/SpecialHitbox
@onready var attack_timer: Timer = $AttackTimer
@onready var active_hitbox_timer: Timer = $ActiveHitboxTimer
@onready var combo_reset_timer: Timer = $ComboResetTimer
@onready var ranged_cooldown_timer: Timer = $RangedCooldownTimer
@onready var charge_cooldown_timer: Timer = $ChargeCooldownTimer
@onready var special_cooldown_timer: Timer = $SpecialCooldownTimer
@onready var projectile_spawn: Marker2D = $ProjectileSpawn

func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	active_hitbox_timer.timeout.connect(_disable_all_hitboxes)
	combo_reset_timer.timeout.connect(reset_combo)
	_disable_all_hitboxes()

func setup(owner_player: Player) -> void:
	player = owner_player

func is_attack_pressed() -> bool:
	return Input.is_action_pressed("attack")

func is_attack_just_pressed() -> bool:
	return Input.is_action_just_pressed("attack")

func is_charge_just_pressed() -> bool:
	return Input.is_action_just_pressed("charge_attack")

func is_ranged_just_pressed() -> bool:
	return Input.is_action_just_pressed("ranged_attack")

func is_special_just_pressed() -> bool:
	return Input.is_action_just_pressed("special_attack")

func is_block_pressed() -> bool:
	return Input.is_action_pressed("block")

func can_start_melee(cost: float) -> bool:
	return _can_act() and player.game_state != null and player.game_state.stamina >= cost

func can_start_ranged() -> bool:
	return _can_act() and ranged_cooldown_timer.time_left <= 0.0 and player.game_state != null and player.game_state.stamina >= ranged_stamina_cost and player.game_state.projectiles > 0

func can_start_charge() -> bool:
	return _can_act() and charge_cooldown_timer.time_left <= 0.0 and player.game_state != null and player.game_state.stamina >= charged_stamina_cost

func can_start_special() -> bool:
	return _can_act() and special_cooldown_timer.time_left <= 0.0 and player.game_state != null and player.game_state.stamina >= special_stamina_cost and player.game_state.magic >= special_magic_cost

func can_block() -> bool:
	return _can_act() and player.is_on_floor() and player.game_state != null and player.game_state.stamina > 0.0

func start_ground_combo() -> bool:
	if player.game_state == null or not player.game_state.use_stamina(combo_stamina_cost):
		return false
	combo_reset_timer.stop()
	combo_step = (combo_step % player.max_combo_step) + 1
	combo_window_open = true
	queued_combo = false
	current_action = "attack_ground"
	activate_hitbox(ground_hitbox, {
		"damage": 1 + int(combo_step == player.max_combo_step),
		"knockback": Vector2((110 + combo_step * 25) * player.facing, -110),
		"attack_tag": "ground_combo_%d" % combo_step
	}, 0.11)
	attack_timer.start(0.22)
	action_started.emit(current_action)
	return true

func start_crouch_attack() -> bool:
	if player.game_state == null or not player.game_state.use_stamina(crouch_stamina_cost):
		return false
	combo_reset_timer.stop()
	current_action = "attack_crouch"
	queued_combo = false
	combo_window_open = false
	activate_hitbox(crouch_hitbox, {
		"damage": 2,
		"knockback": Vector2(135 * player.facing, -65),
		"attack_tag": "crouch_attack"
	}, 0.14)
	attack_timer.start(0.28)
	action_started.emit(current_action)
	return true

func start_air_attack() -> bool:
	if player.game_state == null or not player.game_state.use_stamina(air_stamina_cost):
		return false
	combo_reset_timer.stop()
	current_action = "attack_air"
	queued_combo = false
	combo_window_open = false
	activate_hitbox(air_hitbox, {
		"damage": 2,
		"knockback": Vector2(100 * player.facing, -150),
		"attack_tag": "air_attack"
	}, 0.12)
	attack_timer.start(0.28)
	action_started.emit(current_action)
	return true

func start_charge_attack() -> bool:
	if player.game_state == null or not player.game_state.use_stamina(charged_stamina_cost):
		return false
	combo_reset_timer.stop()
	current_action = "attack_charge"
	queued_combo = false
	combo_window_open = false
	charge_cooldown_timer.start(charge_cooldown)
	activate_hitbox(charge_hitbox, {
		"damage": 4,
		"knockback": Vector2(220 * player.facing, -140),
		"attack_tag": "charged_attack"
	}, 0.18)
	attack_timer.start(0.52)
	action_started.emit(current_action)
	return true

func start_ranged_attack() -> bool:
	if player.game_state == null:
		return false
	combo_reset_timer.stop()
	if not player.game_state.use_stamina(ranged_stamina_cost):
		return false
	if not player.game_state.use_projectile(1):
		player.game_state.restore_stamina(ranged_stamina_cost)
		return false
	current_action = "attack_ranged"
	queued_combo = false
	combo_window_open = false
	ranged_cooldown_timer.start(ranged_cooldown)
	_fire_projectile()
	attack_timer.start(0.2)
	action_started.emit(current_action)
	return true

func start_special_attack() -> bool:
	if player.game_state == null:
		return false
	combo_reset_timer.stop()
	if not player.game_state.use_stamina(special_stamina_cost):
		return false
	if not player.game_state.use_magic(special_magic_cost):
		player.game_state.restore_stamina(special_stamina_cost)
		return false
	current_action = "attack_special"
	queued_combo = false
	combo_window_open = false
	special_cooldown_timer.start(special_cooldown)
	activate_hitbox(special_hitbox, {
		"damage": 5,
		"knockback": Vector2(240 * player.facing, -180),
		"attack_tag": "special_attack"
	}, 0.2)
	attack_timer.start(0.48)
	action_started.emit(current_action)
	return true

func start_block() -> void:
	blocking = true
	current_action = "block"
	block_started.emit()
	action_started.emit(current_action)

func stop_block() -> void:
	if not blocking:
		return
	blocking = false
	current_action = ""
	block_ended.emit()
	action_finished.emit("block")

func spend_block_stamina(delta: float) -> void:
	if not blocking or player.game_state == null:
		return
	if not player.game_state.use_stamina(block_stamina_drain * delta):
		stop_block()

func is_busy() -> bool:
	return current_action != "" and current_action != "block"

func is_blocking() -> bool:
	return blocking

func queue_combo() -> void:
	queued_combo = true

func consume_queued_combo() -> bool:
	if not queued_combo:
		return false
	queued_combo = false
	return true

func finish_action() -> void:
	var finished_action := current_action
	_disable_all_hitboxes()
	current_action = ""
	if finished_action != "":
		action_finished.emit(finished_action)

func cancel_actions() -> void:
	_disable_all_hitboxes()
	current_action = ""
	queued_combo = false

func reset_combo() -> void:
	combo_step = 0
	combo_window_open = false
	queued_combo = false

func can_block_hit(hit_knockback: Vector2) -> bool:
	if not blocking:
		return false
	var incoming_from_front := signf(hit_knockback.x) == float(player.facing)
	return incoming_from_front or is_zero_approx(hit_knockback.x)

func activate_hitbox(hitbox: AttackHitbox, config: Dictionary, duration: float) -> void:
	_disable_all_hitboxes()
	hitbox.scale.x = 1.0
	hitbox.activate({
		"owner": player,
		"damage": int(config.get("damage", 1)),
		"knockback": config.get("knockback", Vector2(120 * player.facing, -120)),
		"attack_tag": str(config.get("attack_tag", "attack"))
	})
	active_hitbox_timer.start(duration)

func _disable_all_hitboxes() -> void:
	ground_hitbox.deactivate()
	crouch_hitbox.deactivate()
	air_hitbox.deactivate()
	charge_hitbox.deactivate()
	special_hitbox.deactivate()

func _fire_projectile() -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)
	projectile.setup({
		"position": projectile_spawn.global_position,
		"direction": Vector2.RIGHT * player.facing,
		"owner": player,
		"damage": 2,
		"speed": 250.0,
		"lifetime": 1.6,
		"knockback": Vector2(180 * player.facing, -70),
		"attack_tag": "ranged_attack"
	})
	projectile_fired.emit(projectile)

func _on_attack_timer_timeout() -> void:
	finish_action()

func _can_act() -> bool:
	return player != null and not player.is_dead
