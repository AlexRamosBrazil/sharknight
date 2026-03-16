class_name GameState
extends Node

signal stats_changed
signal checkpoint_changed(position: Vector2)
signal player_died
signal area_changed(area_name: String)
signal boss_changed(active: bool, boss_name: String, current_health: float, max_health: float)
signal progression_changed

const SAVE_VERSION := 2

@export var max_health: int = 5
@export var max_stamina: float = 100.0
@export var max_magic: float = 60.0
@export var max_projectiles: int = 8
@export var base_max_health: int = 5
@export var base_max_magic: float = 60.0

var health: int
var stamina: float
var magic: float
var projectiles: int
var coins: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint := false
var current_level_path := "res://scenes/levels/coast/Level_CoastKingdom.tscn"
var checkpoint_tag := "start"
var current_area_name := "Costa do Reino Afogado"
var boss_active := false
var boss_name := ""
var boss_health := 0.0
var boss_max_health := 0.0
var unlocked_abilities := _default_unlocked_abilities()

func _ready() -> void:
	reset_for_new_game()

func reset_for_new_game() -> void:
	max_health = base_max_health
	max_magic = base_max_magic
	health = max_health
	stamina = max_stamina
	magic = max_magic
	projectiles = max_projectiles
	coins = 0
	checkpoint_position = Vector2.ZERO
	has_checkpoint = false
	current_level_path = "res://scenes/levels/coast/Level_CoastKingdom.tscn"
	checkpoint_tag = "start"
	current_area_name = "Costa do Reino Afogado"
	boss_active = false
	boss_name = ""
	boss_health = 0.0
	boss_max_health = 0.0
	unlocked_abilities = _default_unlocked_abilities()
	stats_changed.emit()
	area_changed.emit(current_area_name)
	boss_changed.emit(boss_active, boss_name, boss_health, boss_max_health)
	progression_changed.emit()

func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()
	if health <= 0:
		player_died.emit()

func damage(amount: int) -> void:
	set_health(health - amount)

func heal(amount: int) -> void:
	set_health(health + amount)

func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina = clampf(stamina - amount, 0.0, max_stamina)
	stats_changed.emit()
	return true

func restore_stamina(amount: float) -> void:
	stamina = clampf(stamina + amount, 0.0, max_stamina)
	stats_changed.emit()

func use_magic(amount: float) -> bool:
	if magic < amount:
		return false
	magic = clampf(magic - amount, 0.0, max_magic)
	stats_changed.emit()
	return true

func restore_magic(amount: float) -> void:
	magic = clampf(magic + amount, 0.0, max_magic)
	stats_changed.emit()

func use_projectile(amount: int = 1) -> bool:
	if projectiles < amount:
		return false
	projectiles = maxi(projectiles - amount, 0)
	stats_changed.emit()
	return true

func refill_projectiles(amount: int = 1) -> void:
	projectiles = mini(projectiles + amount, max_projectiles)
	stats_changed.emit()

func add_coin(amount: int = 1) -> void:
	coins += amount
	stats_changed.emit()
	progression_changed.emit()

func set_checkpoint(position: Vector2, tag := "start", level_path := current_level_path) -> void:
	checkpoint_position = position
	has_checkpoint = true
	checkpoint_tag = tag
	current_level_path = level_path
	checkpoint_changed.emit(position)
	progression_changed.emit()

func set_area_name(area_name: String) -> void:
	current_area_name = area_name
	area_changed.emit(area_name)

func set_boss_state(active: bool, display_name := "", current_health := 0.0, max_health := 0.0) -> void:
	boss_active = active
	boss_name = display_name
	boss_health = current_health
	boss_max_health = max_health
	boss_changed.emit(active, display_name, current_health, max_health)

func respawn_position(default_position: Vector2) -> Vector2:
	if has_checkpoint:
		return checkpoint_position
	return default_position

func set_current_level(level_path: String) -> void:
	current_level_path = level_path
	progression_changed.emit()

func unlock_ability(ability_id: String) -> void:
	unlocked_abilities[ability_id] = true
	progression_changed.emit()

func has_ability(ability_id: String) -> bool:
	return bool(unlocked_abilities.get(ability_id, false))

func increase_max_health(amount: int) -> void:
	max_health += amount
	health = min(health + amount, max_health)
	stats_changed.emit()
	progression_changed.emit()

func increase_max_magic(amount: float) -> void:
	max_magic += amount
	magic = min(magic + amount, max_magic)
	stats_changed.emit()
	progression_changed.emit()

func to_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"max_health": max_health,
		"health": health,
		"max_stamina": max_stamina,
		"stamina": stamina,
		"max_magic": max_magic,
		"magic": magic,
		"max_projectiles": max_projectiles,
		"projectiles": projectiles,
		"coins": coins,
		"current_level_path": current_level_path,
		"checkpoint_tag": checkpoint_tag,
		"checkpoint_position": {"x": checkpoint_position.x, "y": checkpoint_position.y},
		"has_checkpoint": has_checkpoint,
		"current_area_name": current_area_name,
		"unlocked_abilities": unlocked_abilities.duplicate(true)
	}

func apply_save_data(data: Dictionary) -> void:
	max_health = int(data.get("max_health", base_max_health))
	health = clampi(int(data.get("health", max_health)), 0, max_health)
	max_stamina = float(data.get("max_stamina", max_stamina))
	stamina = clampf(float(data.get("stamina", max_stamina)), 0.0, max_stamina)
	max_magic = float(data.get("max_magic", base_max_magic))
	magic = clampf(float(data.get("magic", max_magic)), 0.0, max_magic)
	max_projectiles = int(data.get("max_projectiles", max_projectiles))
	projectiles = clampi(int(data.get("projectiles", max_projectiles)), 0, max_projectiles)
	coins = int(data.get("coins", 0))
	var save_version: int = int(data.get("save_version", 0))
	current_level_path = str(data.get("current_level_path", current_level_path))
	checkpoint_tag = str(data.get("checkpoint_tag", "start"))
	var checkpoint_dict: Dictionary = data.get("checkpoint_position", {"x": checkpoint_position.x, "y": checkpoint_position.y}) as Dictionary
	checkpoint_position = Vector2(float(checkpoint_dict.get("x", 0.0)), float(checkpoint_dict.get("y", 0.0)))
	has_checkpoint = bool(data.get("has_checkpoint", false))
	current_area_name = str(data.get("current_area_name", current_area_name))
	var saved_abilities: Dictionary = data.get("unlocked_abilities", {}) as Dictionary
	var default_abilities: Dictionary = _default_unlocked_abilities()
	for ability_id in saved_abilities.keys():
		if save_version <= 1 and not bool(saved_abilities[ability_id]):
			continue
		default_abilities[ability_id] = bool(saved_abilities[ability_id])
	unlocked_abilities = default_abilities
	stats_changed.emit()
	area_changed.emit(current_area_name)
	boss_changed.emit(false, "", 0.0, 0.0)
	progression_changed.emit()

func _default_unlocked_abilities() -> Dictionary:
	return {
		"double_jump": true,
		"dash": true,
		"wall_slide": true,
		"wall_jump": true,
		"ladder_climb": true,
		"ledge_hang": true,
		"swim": true
	}
