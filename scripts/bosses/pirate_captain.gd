extends BossBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/combat/EnemyProjectile.tscn")

@export var slash_cooldown := 1.0
@export var pistol_cooldown := 1.5
@export var lunge_speed := 180.0

var _pending_attack := ""
var _is_lunging := false

@onready var projectile_spawn: Marker2D = $ProjectileSpawn

func _ready() -> void:
	boss_name = "Pirate Captain"
	max_health = 18
	contact_damage = 2
	chase_speed = 52.0
	attack_range = 28.0
	super._ready()

func update_boss(_delta: float) -> void:
	if not can_see_player():
		patrol()
		return
	face_target()
	if _is_lunging:
		set_state("lunge")
		velocity.x = lunge_speed * facing
		return
	if player_in_attack_range() and attack_ready():
		_pending_attack = "slash"
		set_vulnerable(false)
		telegraph(0.45, "telegraph_slash")
		start_attack_cooldown(slash_cooldown)
		return
	if current_phase >= 2 and attack_ready():
		_pending_attack = "pistol"
		set_vulnerable(false)
		telegraph(0.5, "telegraph_shot")
		start_attack_cooldown(pistol_cooldown)
		return
	chase_target(chase_speed + (8.0 if current_phase >= 3 else 0.0))

func on_telegraph_finished() -> void:
	match _pending_attack:
		"slash":
			_is_lunging = true
			set_vulnerable(true)
		"pistol":
			_fire_pistol()
			set_vulnerable(true)
			set_state("recover")
	_pending_attack = ""

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _is_lunging and absf(velocity.x) < 10.0:
		_is_lunging = false
		set_state("recover")

func _fire_pistol() -> void:
	if not is_instance_valid(target_player):
		return
	for shot_index in range(1 if current_phase == 2 else 2):
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as EnemyProjectile
		get_parent().add_child(projectile)
		var spread := -0.12 + shot_index * 0.24 if current_phase >= 3 else 0.0
		var direction := (target_player.global_position - projectile_spawn.global_position).normalized().rotated(spread)
		projectile.setup({
			"position": projectile_spawn.global_position,
			"direction": direction,
			"owner": self,
			"speed": 170.0,
			"damage": 1,
			"knockback": Vector2(130 * facing, -60)
		})

func _on_contact_area_body_entered(body: Node) -> void:
	if _is_lunging:
		deal_contact_damage(body, Vector2(190 * facing, -150))
		_is_lunging = false
	else:
		deal_contact_damage(body, Vector2(150 * facing, -110))

func on_phase_changed(phase: int) -> void:
	if phase == 2:
		modulate = Color(1.0, 0.9, 0.85)
	elif phase == 3:
		modulate = Color(1.0, 0.82, 0.82)

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(18, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.72, 0.29, 0.19))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
