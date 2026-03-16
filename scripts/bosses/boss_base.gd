class_name BossBase
extends EnemyBase

signal boss_started(boss: BossBase)
signal boss_defeated(boss: BossBase)

@export var boss_name := "Boss"
@export var phase_two_threshold := 0.66
@export var phase_three_threshold := 0.33
@export var starts_inactive := true

var encounter_started := false
var vulnerable := true
var current_phase := 1

@onready var telegraph_timer: Timer = get_node_or_null("TelegraphTimer")

func _ready() -> void:
	super._ready()
	if telegraph_timer:
		telegraph_timer.timeout.connect(_on_telegraph_timeout)

func activate_boss() -> void:
	if encounter_started:
		return
	encounter_started = true
	set_state("intro")
	_sync_boss_health()
	boss_started.emit(self)

func bind_target_player(player: Node2D) -> void:
	target_player = player
	_sync_boss_health()

func update_enemy(delta: float) -> void:
	if starts_inactive and not encounter_started:
		stop_moving()
		set_state("idle")
		return
	_update_phase()
	update_boss(delta)
	_sync_boss_health()

func update_boss(_delta: float) -> void:
	pass

func set_vulnerable(value: bool) -> void:
	vulnerable = value

func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(health) / float(max_health)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if not encounter_started and starts_inactive:
		return
	if not vulnerable:
		_show_hurt_flash()
		return
	super.take_damage(amount, knockback)
	_sync_boss_health()

func die() -> void:
	if is_dead:
		return
	var state: GameState = _get_game_state()
	if state:
		state.set_boss_state(false)
	super.die()
	boss_defeated.emit(self)

func telegraph(duration: float, telegraph_state := "telegraph") -> void:
	set_state(telegraph_state)
	if telegraph_timer:
		telegraph_timer.start(duration)

func on_telegraph_finished() -> void:
	pass

func _update_phase() -> void:
	var ratio := get_health_ratio()
	var next_phase := 1
	if ratio <= phase_three_threshold:
		next_phase = 3
	elif ratio <= phase_two_threshold:
		next_phase = 2
	if current_phase != next_phase:
		current_phase = next_phase
		on_phase_changed(current_phase)

func on_phase_changed(_phase: int) -> void:
	pass

func _sync_boss_health() -> void:
	var state: GameState = _get_game_state()
	if state:
		state.set_boss_state(encounter_started and not is_dead, boss_name, health, max_health)

func _on_telegraph_timeout() -> void:
	on_telegraph_finished()

func _get_game_state() -> GameState:
	if target_player and target_player.has_method("get_game_state"):
		return target_player.get_game_state() as GameState
	return null
