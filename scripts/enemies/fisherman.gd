extends EnemyBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/combat/EnemyProjectile.tscn")

@export var throw_cooldown := 1.4
@export var throw_speed := 170.0

@onready var projectile_spawn: Marker2D = $ProjectileSpawn

func _ready() -> void:
	super._ready()
	drop_scene = preload("res://scenes/core/Coin.tscn")
	drop_count = 1

func update_enemy(_delta: float) -> void:
	if can_see_player():
		face_target()
		stop_moving()
		set_state("throw")
		if attack_ready():
			start_attack_cooldown(throw_cooldown)
			_throw_hook()
	else:
		patrol()

func _throw_hook() -> void:
	if not is_instance_valid(target_player):
		return
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as EnemyProjectile
	get_parent().add_child(projectile)
	projectile.setup({
		"position": projectile_spawn.global_position,
		"direction": (target_player.global_position - projectile_spawn.global_position).normalized(),
		"owner": self,
		"speed": throw_speed,
		"damage": contact_damage,
		"knockback": Vector2(120 * facing, -50)
	})

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.77, 0.61, 0.32))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
