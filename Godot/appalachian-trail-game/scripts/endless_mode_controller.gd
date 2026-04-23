extends Node2D
class_name EndlessModeController

const COUGAR_SCENE: PackedScene = preload("res://scenes/entities/enemies/cougar.tscn")
const HIPPIE_SCENE: PackedScene = preload("res://scenes/entities/enemies/hippie.tscn")
const RAM_SCENE: PackedScene = preload("res://scenes/entities/enemies/ram.tscn")

@export var player: Node2D
@export var spawn_radius: float = 800.0
@export var spawn_interval: float = 0.75
@export var max_active_enemies: int = 30
@export var autostart: bool = true

var active_enemies: int = 0

var _timer: Timer
var _running: bool = false

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = maxf(spawn_interval, 0.01)
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	if autostart:
		start()

func set_player(new_player: Node2D) -> void:
	player = new_player

func start() -> void:
	if _running:
		return
	_running = true
	_timer.wait_time = maxf(spawn_interval, 0.01)
	_timer.start()

func stop() -> void:
	_running = false
	if _timer:
		_timer.stop()

func _on_timer_timeout() -> void:
	if not _running:
		return

	if player == null or not is_instance_valid(player):
		stop()
		return

	if max_active_enemies > 0 and active_enemies >= max_active_enemies:
		return

	spawn_once()

func spawn_once() -> Node:
	if player == null or not is_instance_valid(player):
		return null

	var enemy_scene := _pick_enemy_scene()
	if enemy_scene == null:
		return null

	var enemy_instance: Node = enemy_scene.instantiate()
	if enemy_instance == null:
		return null

	var spawn_parent: Node = _get_spawn_parent()
	if spawn_parent == null:
		enemy_instance.queue_free()
		return null

	if enemy_instance is Node2D:
		var enemy_2d := enemy_instance as Node2D
		var random_angle: float = randf() * TAU
		var spawn_direction: Vector2 = Vector2.RIGHT.rotated(random_angle)
		enemy_2d.global_position = player.global_position + (spawn_direction * spawn_radius)

	enemy_instance.tree_exited.connect(_on_enemy_removed)
	active_enemies += 1
	spawn_parent.add_child(enemy_instance)
	return enemy_instance

func _pick_enemy_scene() -> PackedScene:
	var roll := randi() % 3
	if roll == 0:
		return COUGAR_SCENE
	if roll == 1:
		return RAM_SCENE
	return HIPPIE_SCENE

func _get_spawn_parent() -> Node:
	if get_parent() != null:
		return get_parent()
	if get_tree() != null and get_tree().current_scene != null:
		return get_tree().current_scene
	return null

func _on_enemy_removed() -> void:
	active_enemies = maxi(active_enemies - 1, 0)
