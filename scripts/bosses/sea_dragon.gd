extends BossBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/combat/EnemyProjectile.tscn")

@export var hover_amplitude := 24.0
@export var hover_speed := 1.3
@export var dive_speed := 190.0

var _time := 0.0
var _pending_attack := ""
var _is_diving := false

@onready var projectile_spawn: Marker2D = $ProjectileSpawn

func _ready() -> void:
	boss_name = "Sea Dragon"
	max_health = 24
	contact_damage = 3
	use_gravity = false
	chase_range = 260.0
	attack_range = 90.0
	super._ready()

func update_boss(delta: float) -> void:
	_time += delta
	if _is_diving and is_instance_valid(target_player):
		set_state("dive")
		var direction := (target_player.global_position - global_position).normalized()
		velocity = direction * dive_speed
		facing = 1 if direction.x > 0.0 else -1
		return
	velocity = Vector2.ZERO
	global_position = Vector2(
		spawn_position.x + sin(_time * hover_speed) * 26.0,
		spawn_position.y + sin(_time * hover_speed * 2.0) * hover_amplitude
	)
	if not can_see_player():
		set_state("hover")
		return
	face_target()
	if attack_ready():
		if current_phase == 1:
			_pending_attack = "fireball"
			set_vulnerable(false)
			telegraph(0.55, "telegraph_fire")
			start_attack_cooldown(1.4)
		elif current_phase == 2:
			_pending_attack = "dive"
			set_vulnerable(false)
			telegraph(0.7, "telegraph_dive")
			start_attack_cooldown(1.6)
		else:
			_pending_attack = "storm"
			set_vulnerable(false)
			telegraph(0.75, "telegraph_storm")
			start_attack_cooldown(1.9)

func on_telegraph_finished() -> void:
	match _pending_attack:
		"fireball":
			_shoot_fireball(1)
			set_vulnerable(true)
			set_state("recover")
		"dive":
			_is_diving = true
			set_vulnerable(true)
		"storm":
			_shoot_fireball(3)
			set_vulnerable(true)
			set_state("recover")
	_pending_attack = ""

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _is_diving and absf(velocity.x) < 20.0:
		_is_diving = false
		set_state("recover")

func _shoot_fireball(amount: int) -> void:
	if not is_instance_valid(target_player):
		return
	for shot_index in range(amount):
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as EnemyProjectile
		get_parent().add_child(projectile)
		var spread := 0.0
		if amount > 1:
			spread = -0.22 + shot_index * 0.22
		var direction := (target_player.global_position - projectile_spawn.global_position).normalized().rotated(spread)
		projectile.setup({
			"position": projectile_spawn.global_position,
			"direction": direction,
			"owner": self,
			"speed": 155.0,
			"damage": 2,
			"knockback": Vector2(160 * signf(direction.x if direction.x != 0.0 else facing), -80)
		})

func _on_contact_area_body_entered(body: Node) -> void:
	deal_contact_damage(body, Vector2(220 * facing, -160))
	if _is_diving:
		_is_diving = false
		set_state("recover")

func on_phase_changed(phase: int) -> void:
	if phase == 2:
		modulate = Color(0.8, 1.0, 0.93)
	elif phase == 3:
		modulate = Color(0.74, 0.9, 1.0)

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(28, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.28, 0.74, 0.7))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
