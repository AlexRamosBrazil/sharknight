extends EnemyBase

@export var drift_amplitude := 14.0
@export var drift_speed := 1.9
@export var pulse_cooldown := 1.4
@export var pulse_speed := 110.0

var _time := 0.0
var _pulse_velocity := Vector2.ZERO

func _ready() -> void:
	max_health = 3
	contact_damage = 2
	use_gravity = false
	chase_range = 150.0
	super._ready()
	drop_scene = preload("res://scenes/core/ManaPickup.tscn")
	drop_count = 1

func update_enemy(delta: float) -> void:
	_time += delta
	if _pulse_velocity.length() > 1.0:
		set_state("pulse")
		velocity = _pulse_velocity
		_pulse_velocity = _pulse_velocity.move_toward(Vector2.ZERO, pulse_speed * delta * 2.2)
		if velocity.x != 0.0:
			facing = 1 if velocity.x > 0.0 else -1
		return
	velocity = Vector2.ZERO
	global_position = Vector2(
		spawn_position.x + sin(_time * drift_speed) * drift_amplitude,
		spawn_position.y + cos(_time * drift_speed * 1.6) * drift_amplitude
	)
	if can_see_player():
		face_target()
		set_state("charge")
		if attack_ready() and is_instance_valid(target_player):
			start_attack_cooldown(pulse_cooldown)
			_pulse_velocity = (target_player.global_position - global_position).normalized() * pulse_speed
	else:
		set_state("hover")

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(10, 14, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.55, 0.78, 1.0))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
