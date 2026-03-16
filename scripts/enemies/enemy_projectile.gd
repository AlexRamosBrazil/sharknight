class_name EnemyProjectile
extends Area2D

@export var speed := 180.0
@export var lifetime := 2.0
@export var damage := 1
@export var knockback := Vector2(130, -70)

var direction := Vector2.RIGHT
var owner_enemy: Node

@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	life_timer.timeout.connect(queue_free)
	life_timer.start(lifetime)

func setup(config: Dictionary) -> void:
	global_position = config.get("position", global_position)
	direction = (config.get("direction", direction) as Vector2).normalized()
	speed = float(config.get("speed", speed))
	damage = int(config.get("damage", damage))
	lifetime = float(config.get("lifetime", lifetime))
	knockback = config.get("knockback", knockback)
	owner_enemy = config.get("owner", owner_enemy)
	scale.x = 1.0 if direction.x >= 0.0 else -1.0

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body == owner_enemy:
		return
	if body.is_in_group("player"):
		var applied_knockback := knockback
		if applied_knockback.x != 0.0:
			applied_knockback.x *= signf(direction.x) if direction.x != 0.0 else 1.0
		body.take_damage(damage, applied_knockback)
		queue_free()
