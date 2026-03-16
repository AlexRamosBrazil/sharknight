extends EnemyBase

@export var attack_cooldown := 0.8

func _ready() -> void:
	super._ready()
	drop_scene = preload("res://scenes/core/Coin.tscn")
	drop_count = 1

func update_enemy(_delta: float) -> void:
	if can_see_player():
		face_target()
		if player_in_attack_range():
			set_state("attack")
			stop_moving()
			if attack_ready():
				start_attack_cooldown(attack_cooldown)
				if is_instance_valid(target_player):
					deal_contact_damage(target_player, Vector2(160 * facing, -130))
		else:
			chase_target()
	else:
		patrol()

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.84, 0.39, 0.25))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
