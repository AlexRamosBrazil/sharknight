class_name Projectile
extends Area2D

@export var speed := 220.0
@export var lifetime := 1.6

var direction := Vector2.RIGHT
var owner_node: Node

@onready var hitbox: AttackHitbox = $Hitbox
@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	life_timer.timeout.connect(queue_free)
	hitbox.hit_landed.connect(_on_hit_landed)
	life_timer.start(lifetime)

func setup(config: Dictionary) -> void:
	global_position = config.get("position", global_position)
	direction = (config.get("direction", Vector2.RIGHT) as Vector2).normalized()
	owner_node = config.get("owner", owner_node)
	speed = float(config.get("speed", speed))
	lifetime = float(config.get("lifetime", lifetime))
	hitbox.activate({
		"owner": owner_node,
		"damage": int(config.get("damage", 1)),
		"knockback": config.get("knockback", Vector2(150 * signf(direction.x), -60)),
		"attack_tag": str(config.get("attack_tag", "projectile"))
	})
	scale.x = 1.0 if direction.x >= 0.0 else -1.0

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_hit_landed(_target: Node) -> void:
	queue_free()
