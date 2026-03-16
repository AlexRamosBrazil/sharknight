extends EnemyBase

@export var hover_amplitude := 18.0
@export var hover_speed := 2.0
@export var dive_speed := 160.0

var _time := 0.0
var _is_diving := false

@onready var hit_area: Area2D = $HitArea

func _ready() -> void:
	use_gravity = false
	super._ready()
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)

func update_enemy(delta: float) -> void:
	_time += delta
	if can_see_player():
		set_state("dive")
		_is_diving = true
	if _is_diving and is_instance_valid(target_player):
		var direction := (target_player.global_position - global_position).normalized()
		velocity = direction * dive_speed
		facing = 1 if direction.x > 0.0 else -1
	else:
		set_state("hover")
		velocity = Vector2.ZERO
		global_position = Vector2(
			spawn_position.x + sin(_time * hover_speed) * 10.0,
			spawn_position.y + sin(_time * hover_speed * 2.0) * hover_amplitude
		)

func _on_hit_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		deal_contact_damage(body, Vector2(120 * facing, -120))
		_is_diving = false
		target_player = null

func _apply_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var image := Image.create(12, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.62, 0.5, 0.81))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
