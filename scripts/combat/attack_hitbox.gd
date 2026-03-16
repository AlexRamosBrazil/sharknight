class_name AttackHitbox
extends Area2D

signal hit_landed(target: Node)

@export var damage: int = 1
@export var knockback := Vector2(120, -120)
@export var hit_stun: float = 0.0

var owner_node: Node
var attack_tag := ""
var _hit_targets: Array[Node] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func activate(config: Dictionary) -> void:
	damage = int(config.get("damage", damage))
	knockback = config.get("knockback", knockback)
	hit_stun = float(config.get("hit_stun", hit_stun))
	attack_tag = str(config.get("attack_tag", attack_tag))
	owner_node = config.get("owner", owner_node)
	_hit_targets.clear()
	monitoring = true
	monitorable = true

func deactivate() -> void:
	monitoring = false
	monitorable = false
	_hit_targets.clear()

func _on_area_entered(area: Area2D) -> void:
	if not (area is Hurtbox):
		return
	var hurtbox := area as Hurtbox
	var receiver := hurtbox.damage_receiver
	if receiver == null or receiver == owner_node or _hit_targets.has(receiver):
		return
	_hit_targets.append(receiver)
	hurtbox.receive_hit(self)
	hit_landed.emit(receiver)
