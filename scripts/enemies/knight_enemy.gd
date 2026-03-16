extends EnemyBase

@export var counter_cooldown := 1.1
@export var guard_range := 60.0

var is_guarding := false

func _ready() -> void:
	max_health = 4
	contact_damage = 2
	super._ready()
	drop_scene = preload("res://scenes/core/Coin.tscn")
	drop_count = 2

func update_enemy(_delta: float) -> void:
	if can_see_player():
		face_target()
		is_guarding = global_position.distance_to(target_player.global_position) <= guard_range
		if player_in_attack_range():
			set_state("counter")
			stop_moving()
			if attack_ready():
				start_attack_cooldown(counter_cooldown)
				if is_instance_valid(target_player):
					deal_contact_damage(target_player, Vector2(170 * facing, -130))
		else:
			set_state("guard" if is_guarding else "chase")
			chase_target(46.0)
	else:
		is_guarding = false
		patrol()

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	var incoming_from_front := (knockback.x < 0.0 and facing > 0) or (knockback.x > 0.0 and facing < 0)
	if is_guarding and incoming_from_front:
		_show_hurt_flash()
		start_attack_cooldown(0.25)
		return
	super.take_damage(amount, knockback)

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.47, 0.58, 0.78))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
