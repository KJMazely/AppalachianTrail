extends Node2D

const COUGAR_SCENE := preload("res://scenes/entities/enemies/cougar.tscn")
const RAM_SCENE := preload("res://scenes/entities/enemies/ram.tscn")

func _ready() -> void:
	var wave_controller: WaveController = $WaveController
	if wave_controller == null:
		return

	wave_controller.waves = _build_main_waves()

	if not wave_controller.waves_completed.is_connected(_on_waves_completed):
		wave_controller.waves_completed.connect(_on_waves_completed)

func _on_waves_completed() -> void:
	ScoreManager.end_game()

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
	return null

func _get_boss_scene() -> PackedScene:
	# Replace `return null` with:
	# return preload("res://path/to/your/boss_enemy.tscn")
	return null
