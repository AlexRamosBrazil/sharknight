extends EnemyBase

@export var burst_speed := 120.0
@export var burst_duration := 0.35
@export var burst_cooldown := 1.2

var _burst_time_left := 0.0

func _ready() -> void:
	max_health = 3
	contact_damage = 1
	patrol_speed = 28.0
	chase_range = 110.0
	attack_range = 42.0
	super._ready()
	drop_scene = preload("res://scenes/core/Coin.tscn")
	drop_count = 1

func update_enemy(delta: float) -> void:
	if _burst_time_left > 0.0:
		_burst_time_left = maxf(_burst_time_left - delta, 0.0)
		set_state("burst")
		velocity.x = burst_speed * facing
		return
	if can_see_player():
		face_target()
		if player_in_attack_range() and attack_ready():
			start_attack_cooldown(burst_cooldown)
			_burst_time_left = burst_duration
			velocity.x = burst_speed * facing
			set_state("burst")
			return
		chase_target(40.0)
		return
	patrol()

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(14, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.94, 0.46, 0.35))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
