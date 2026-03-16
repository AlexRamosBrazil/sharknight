extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("enter_water_area"):
		body.enter_water_area()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("exit_water_area"):
		body.exit_water_area()
