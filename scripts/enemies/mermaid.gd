extends EnemyBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/combat/EnemyProjectile.tscn")

@export var cast_cooldown := 1.2
@export var drift_amplitude := 12.0
@export var drift_speed := 1.6

var _time := 0.0

@onready var projectile_spawn: Marker2D = $ProjectileSpawn

func _ready() -> void:
	use_gravity = false
	super._ready()
	drop_scene = preload("res://scenes/core/Coin.tscn")
	drop_count = 2

func update_enemy(delta: float) -> void:
	_time += delta
	global_position.y = spawn_position.y + sin(_time * drift_speed) * drift_amplitude
	velocity = Vector2.ZERO
	if can_see_player():
		face_target()
		set_state("cast")
		if attack_ready():
			start_attack_cooldown(cast_cooldown)
			_cast_magic()
	else:
		set_state("idle")

func _cast_magic() -> void:
	if not is_instance_valid(target_player):
		return
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as EnemyProjectile
	get_parent().add_child(projectile)
	projectile.setup({
		"position": projectile_spawn.global_position,
		"direction": (target_player.global_position - projectile_spawn.global_position).normalized(),
		"owner": self,
		"speed": 150.0,
		"damage": max(1, contact_damage + 1),
		"knockback": Vector2(150 * facing, -90)
	})

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.33, 0.84, 0.78))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
