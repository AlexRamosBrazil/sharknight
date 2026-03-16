extends Area2D

@export_file("*.tscn") var next_level_path := ""
@export var target_spawn_tag := "start"
@export var auto_complete_if_empty := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var level := get_parent()
	while level and not level.has_method("request_transition"):
		level = level.get_parent()
	if level:
		if next_level_path != "":
			level.next_level_path = next_level_path
			level.request_transition(target_spawn_tag)
		elif auto_complete_if_empty:
			level.complete_level()
