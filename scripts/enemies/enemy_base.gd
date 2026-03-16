class_name EnemyBase
extends CharacterBody2D

signal enemy_died(enemy: EnemyBase)
signal state_changed(state_name: String)

@export var max_health := 3
@export var contact_damage := 1
@export var gravity := 980.0
@export var use_gravity := true
@export var patrol_distance := 64.0
@export var patrol_speed := 40.0
@export var chase_speed := 58.0
@export var chase_range := 120.0
@export var attack_range := 22.0
@export var knockback_decay := 900.0
@export var hurt_flash_time := 0.12
@export var drop_scene: PackedScene
@export var drop_count := 0

var health := 0
var facing := -1
var spawn_position := Vector2.ZERO
var target_player: Node2D
var enemy_state := "idle"
var is_dead := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var player_detector: Area2D = get_node_or_null("PlayerDetector")
@onready var contact_area: Area2D = get_node_or_null("ContactArea")
@onready var hurt_flash_timer: Timer = get_node_or_null("HurtFlashTimer")
@onready var attack_cooldown_timer: Timer = get_node_or_null("AttackCooldownTimer")

func _ready() -> void:
	add_to_group("enemy")
	spawn_position = global_position
	health = max_health
	if player_detector:
		player_detector.body_entered.connect(_on_player_detector_body_entered)
		player_detector.body_exited.connect(_on_player_detector_body_exited)
	if contact_area:
		contact_area.body_entered.connect(_on_contact_area_body_entered)
	if hurt_flash_timer:
		hurt_flash_timer.timeout.connect(_clear_hurt_flash)
	_apply_placeholder_visual()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if use_gravity and not is_on_floor():
		velocity.y += gravity * delta
	elif use_gravity:
		velocity.y = minf(velocity.y, 0.0)

	velocity.x = move_toward(velocity.x, 0.0, knockback_decay * delta)
	update_enemy(delta)
	move_and_slide()
	_update_visuals()

func update_enemy(_delta: float) -> void:
	pass

func set_state(next_state: String) -> void:
	if enemy_state == next_state:
		return
	enemy_state = next_state
	state_changed.emit(next_state)

func patrol() -> void:
	set_state("patrol")
	velocity.x = patrol_speed * facing
	if absf(global_position.x - spawn_position.x) >= patrol_distance:
		facing *= -1

func chase_target(speed := chase_speed) -> void:
	if not is_instance_valid(target_player):
		return
	set_state("chase")
	var direction := signf(target_player.global_position.x - global_position.x)
	if absf(direction) > 0.0:
		facing = 1 if direction > 0.0 else -1
	velocity.x = speed * facing

func stop_moving() -> void:
	velocity.x = move_toward(velocity.x, 0.0, patrol_speed)

func can_see_player() -> bool:
	return is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) <= chase_range

func player_in_attack_range() -> bool:
	return is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) <= attack_range

func attack_ready() -> bool:
	return attack_cooldown_timer == null or attack_cooldown_timer.time_left <= 0.0

func start_attack_cooldown(duration: float) -> void:
	if attack_cooldown_timer:
		attack_cooldown_timer.start(duration)

func face_target() -> void:
	if not is_instance_valid(target_player):
		return
	facing = 1 if target_player.global_position.x > global_position.x else -1

func deal_contact_damage(body: Node, knockback := Vector2.ZERO) -> void:
	if not body.is_in_group("player"):
		return
	var applied_knockback := knockback
	if applied_knockback == Vector2.ZERO:
		applied_knockback = Vector2(140 * facing, -120)
	body.take_damage(contact_damage, applied_knockback)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	health -= amount
	if knockback != Vector2.ZERO:
		velocity = knockback
		if knockback.x != 0.0:
			facing = 1 if knockback.x > 0.0 else -1
	_show_hurt_flash()
	on_damage_received(amount, knockback)
	if health <= 0:
		die()

func on_damage_received(_amount: int, _knockback: Vector2) -> void:
	set_state("hurt")

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_state("dead")
	_spawn_drops()
	enemy_died.emit(self)
	queue_free()

func _spawn_drops() -> void:
	if drop_scene == null or drop_count <= 0:
		return
	for index in range(drop_count):
		var drop := drop_scene.instantiate()
		get_parent().add_child(drop)
		if drop is Node2D:
			drop.global_position = global_position + Vector2(index * 8 - 4, -6)

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.4, 0.4))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true

func _update_visuals() -> void:
	if sprite:
		sprite.flip_h = facing > 0

func _show_hurt_flash() -> void:
	modulate = Color(1.0, 0.7, 0.7)
	if hurt_flash_timer:
		hurt_flash_timer.start(hurt_flash_time)

func _clear_hurt_flash() -> void:
	modulate = Color(1.0, 1.0, 1.0)

func _on_player_detector_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target_player = body

func _on_player_detector_body_exited(body: Node) -> void:
	if body == target_player:
		target_player = null

func _on_contact_area_body_entered(body: Node) -> void:
	deal_contact_damage(body)
