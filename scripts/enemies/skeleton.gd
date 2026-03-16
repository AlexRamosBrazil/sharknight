extends EnemyBase

func _ready() -> void:
	max_health = 5
	patrol_speed = 24.0
	chase_speed = 30.0
	contact_damage = 2
	super._ready()
	drop_scene = preload("res://scenes/core/Coin.tscn")
	drop_count = 2

func update_enemy(_delta: float) -> void:
	if can_see_player():
		if player_in_attack_range():
			set_state("attack")
			stop_moving()
			if attack_ready():
				start_attack_cooldown(1.0)
				if is_instance_valid(target_player):
					deal_contact_damage(target_player, Vector2(110 * facing, -100))
		else:
			chase_target(chase_speed)
	else:
		patrol()

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.85, 0.85, 0.8))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
