extends Area2D

@export var damage: int = 1
@export var knockback := Vector2(180, -260)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage, knockback)
