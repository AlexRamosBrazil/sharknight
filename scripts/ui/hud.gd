extends CanvasLayer

var game_state: GameState
var player: Node

@onready var area_label: Label = get_node_or_null("Root/TopBar/AreaFrame/AreaLabel")
@onready var health_bar: ProgressBar = get_node_or_null("Root/TopLeft/ResourceFrame/VBoxContainer/HealthBar")
@onready var stamina_bar: ProgressBar = get_node_or_null("Root/TopLeft/ResourceFrame/VBoxContainer/StaminaBar")
@onready var magic_bar: ProgressBar = get_node_or_null("Root/TopLeft/ResourceFrame/VBoxContainer/MagicBar")
@onready var coins_label: Label = get_node_or_null("Root/TopRight/CounterFrame/VBoxContainer/CoinsLabel")
@onready var projectiles_label: Label = get_node_or_null("Root/TopRight/CounterFrame/VBoxContainer/ProjectilesLabel")
@onready var state_label: Label = get_node_or_null("Root/BottomLeft/StateFrame/StateLabel")
@onready var boss_frame: PanelContainer = get_node_or_null("Root/Bottom/BossFrame")
@onready var boss_name_label: Label = get_node_or_null("Root/Bottom/BossFrame/VBoxContainer/BossName")
@onready var boss_bar: ProgressBar = get_node_or_null("Root/Bottom/BossFrame/VBoxContainer/BossBar")

func bind_game_state(state: GameState) -> void:
	game_state = state
	if not is_node_ready():
		await ready
	_cache_nodes()
	if not game_state.stats_changed.is_connected(_refresh_stats):
		game_state.stats_changed.connect(_refresh_stats)
	if not game_state.area_changed.is_connected(_refresh_area):
		game_state.area_changed.connect(_refresh_area)
	if not game_state.boss_changed.is_connected(_refresh_boss):
		game_state.boss_changed.connect(_refresh_boss)
	_refresh_stats()
	_refresh_area(game_state.current_area_name)
	_refresh_boss(game_state.boss_active, game_state.boss_name, game_state.boss_health, game_state.boss_max_health)

func bind_player(player_node: Node) -> void:
	player = player_node
	if not is_node_ready():
		await ready
	_cache_nodes()
	if player and not player.state_changed.is_connected(_on_player_state_changed):
		player.state_changed.connect(_on_player_state_changed)
	if state_label:
		state_label.text = "Estado: idle"

func _refresh_stats() -> void:
	if not game_state:
		return
	if health_bar:
		health_bar.max_value = game_state.max_health
		health_bar.value = game_state.health
	if stamina_bar:
		stamina_bar.max_value = game_state.max_stamina
		stamina_bar.value = game_state.stamina
	if magic_bar:
		magic_bar.max_value = game_state.max_magic
		magic_bar.value = game_state.magic
	if coins_label:
		coins_label.text = "Moedas  %d" % game_state.coins
	if projectiles_label:
		projectiles_label.text = "Projeteis  %d" % game_state.projectiles

func _refresh_area(area_name: String) -> void:
	if area_label:
		area_label.text = area_name

func _refresh_boss(active: bool, display_name: String, current_health: float, max_health: float) -> void:
	if boss_frame == null:
		return
	boss_frame.visible = active
	if not active:
		return
	if boss_name_label:
		boss_name_label.text = display_name
	if boss_bar:
		boss_bar.max_value = max_health
		boss_bar.value = current_health

func _on_player_state_changed(state_name: String) -> void:
	if state_label:
		state_label.text = "Estado: %s" % state_name

func _cache_nodes() -> void:
	area_label = get_node_or_null("Root/TopBar/AreaFrame/AreaLabel")
	health_bar = get_node_or_null("Root/TopLeft/ResourceFrame/VBoxContainer/HealthBar")
	stamina_bar = get_node_or_null("Root/TopLeft/ResourceFrame/VBoxContainer/StaminaBar")
	magic_bar = get_node_or_null("Root/TopLeft/ResourceFrame/VBoxContainer/MagicBar")
	coins_label = get_node_or_null("Root/TopRight/CounterFrame/VBoxContainer/CoinsLabel")
	projectiles_label = get_node_or_null("Root/TopRight/CounterFrame/VBoxContainer/ProjectilesLabel")
	state_label = get_node_or_null("Root/BottomLeft/StateFrame/StateLabel")
	boss_frame = get_node_or_null("Root/Bottom/BossFrame")
	boss_name_label = get_node_or_null("Root/Bottom/BossFrame/VBoxContainer/BossName")
	boss_bar = get_node_or_null("Root/Bottom/BossFrame/VBoxContainer/BossBar")
