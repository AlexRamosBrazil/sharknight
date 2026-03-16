class_name Hurtbox
extends Area2D

signal hit_received(hitbox: AttackHitbox)

@export var damage_receiver_path: NodePath

var damage_receiver: Node

func _ready() -> void:
	damage_receiver = get_node_or_null(damage_receiver_path)
	if damage_receiver == null:
		damage_receiver = get_parent()

func receive_hit(hitbox: AttackHitbox) -> void:
	hit_received.emit(hitbox)
	if damage_receiver and damage_receiver.has_method("take_damage"):
		damage_receiver.take_damage(hitbox.damage, hitbox.knockback)
