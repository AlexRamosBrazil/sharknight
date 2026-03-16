extends Area2D

@export_node_path("Node") var boss_path: NodePath
@export var complete_level_on_boss_defeat := true
var activated := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if activated or not body.is_in_group("player"):
		return
	var boss: Node = get_node_or_null(boss_path)
	if not (boss is BossBase):
		return
	activated = true
	var boss_node := boss as BossBase
	if body is Node2D:
		boss_node.bind_target_player(body as Node2D)
	boss_node.activate_boss()
	if complete_level_on_boss_defeat and not boss_node.boss_defeated.is_connected(_on_boss_defeated):
		boss_node.boss_defeated.connect(_on_boss_defeated.bind(boss_node))

func _on_boss_defeated(_boss: BossBase) -> void:
	var level: Node = get_parent()
	while level and not level.has_method("complete_level"):
		level = level.get_parent()
	if level:
		level.complete_level()
