extends Node2D

const COUGAR_SCENE := preload("res://scenes/entities/enemies/cougar.tscn")
const RAM_SCENE := preload("res://scenes/entities/enemies/ram.tscn")
const BIGFOOT_BOSS_SCENE := preload("res://scenes/entities/enemies/bigfoot_boss.tscn")
const ENDLESS_MODE_CONTROLLER_SCRIPT := preload("res://scripts/endless_mode_controller.gd")

var _endless_controller: Node = null

func _ready() -> void:
	var wave_controller: WaveController = $WaveController
	if wave_controller == null:
		return

	wave_controller.waves = _build_main_waves()

	if not wave_controller.waves_completed.is_connected(_on_waves_completed):
		wave_controller.waves_completed.connect(_on_waves_completed)

	if not ScoreManager.endless_requested.is_connected(_on_endless_requested):
		ScoreManager.endless_requested.connect(_on_endless_requested)

func _on_waves_completed() -> void:
	ScoreManager.end_game("win", true)

func _on_endless_requested() -> void:
	if _endless_controller != null and is_instance_valid(_endless_controller):
		return

	if ENDLESS_MODE_CONTROLLER_SCRIPT == null:
		push_warning("Endless mode controller script missing.")
		return

	var controller: Node = ENDLESS_MODE_CONTROLLER_SCRIPT.new()
	_endless_controller = controller
	add_child(controller)

	if controller.has_method("set_player"):
		controller.call("set_player", get_node_or_null("Player"))
	elif "player" in controller:
		controller.set("player", get_node_or_null("Player"))

	if controller.has_method("start"):
		controller.call("start")

func _build_main_waves() -> Array[Dictionary]:
	return [
		{
			"label": "Animals",
			"entries": [
				# Change cougar count here.
				{"scene": COUGAR_SCENE, "count": 3, "spawn_interval": 0.6},
				# Change ram count here.
				{"scene": RAM_SCENE, "count": 2, "spawn_interval": 0.8},
			],
		},
		{
			"label": "Humans",
			"entries": [
				# When the human enemy exists, replace `_get_human_scene()`
				# with that scene and adjust the count here.
				{"scene": _get_human_scene(), "count": 3, "spawn_interval": 0.7},
			],
		},
		{
			"label": "Animals and Humans",
			"entries": [
				# Change the animal count here.
				{"scene": COUGAR_SCENE, "count": 2, "spawn_interval": 0.5},
				# When the human enemy exists, replace `_get_human_scene()`
				# with that scene and adjust the count here.
				{"scene": _get_human_scene(), "count": 2, "spawn_interval": 0.7},
			],
		},
		{
			"label": "Boss",
			"entries": [
				# When the boss scene exists, replace `_get_boss_scene()`
				# with that scene. This count will usually stay at 1.
				{"scene": _get_boss_scene(), "count": 1},
			],
		},
	]

func _get_human_scene() -> PackedScene:
	# Replace `return null` with:
	# return preload("res://path/to/your/human_enemy.tscn")
	return preload("res://scenes/entities/enemies/hippie.tscn")

func _get_boss_scene() -> PackedScene:
	return BIGFOOT_BOSS_SCENE
