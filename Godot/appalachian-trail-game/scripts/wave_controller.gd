extends Node2D
class_name WaveController

signal wave_started(wave_index: int, wave_label: String)
signal wave_cleared(wave_index: int, wave_label: String)
signal waves_completed
signal enemy_spawned(enemy: Node, wave_index: int, wave_label: String)

@export var waves: Array[Dictionary] = []
@export var inter_wave_delay: float = 1.5
@export var player: Node2D
@export var spawn_radius: float = 800.0
@export var default_spawn_interval: float = 1.5
@export var autostart: bool = true

var current_wave_index: int = -1
var spawned_count: int = 0
var active_enemies: int = 0

var _current_wave_spawn_total: int = 0
var _current_wave_finished_spawning: bool = false
var _advancing_wave: bool = false
var _is_shutting_down: bool = false
var _starting: bool = false

func _get_tilemap_layer() -> TileMapLayer:
	var scene := get_tree().current_scene
	if scene == null:
		return null

	var direct := scene.get_node_or_null("TileMapLayer") as TileMapLayer
	if direct != null:
		return direct

	var found := scene.find_children("*", "TileMapLayer", true, false)
	return found[0] as TileMapLayer if not found.is_empty() else null

func _pick_spawn(desired: Vector2) -> Vector2:
	var m := _get_tilemap_layer(); if m == null: return desired
	var u := m.get_used_rect(); if u.size.x <= 0 or u.size.y <= 0: return desired
	var minc := u.position; var maxc := u.position + u.size - Vector2i.ONE
	var base := m.local_to_map(m.to_local(desired))
	var mask := int(m.tile_set.get_physics_layer_collision_layer(0)) if m.tile_set != null else 0
	var space := get_world_2d().direct_space_state
	var exclude: Array[RID] = []; if player != null and is_instance_valid(player): exclude = [player.get_rid()]

	for _i in range(20):
		var c := Vector2i(clamp(base.x + randi_range(-6, 6), minc.x, maxc.x), clamp(base.y + randi_range(-6, 6), minc.y, maxc.y))
		if m.get_cell_source_id(c) == -1: continue
		var w := m.to_global(m.map_to_local(c))
		if mask != 0:
			var q := PhysicsPointQueryParameters2D.new()
			q.position = w; q.collision_mask = mask; q.collide_with_bodies = true; q.collide_with_areas = false; q.exclude = exclude
			if not space.intersect_point(q, 1).is_empty(): continue
		return w
	return m.to_global(m.map_to_local(Vector2i(clamp(base.x, minc.x, maxc.x), clamp(base.y, minc.y, maxc.y))))
func _ready() -> void:
	_is_shutting_down = false
	if autostart:
		call_deferred("start_waves")

func _exit_tree() -> void:
	_is_shutting_down = true

func start_waves() -> void:
	if _starting or _is_shutting_down:
		return

	_starting = true
	current_wave_index = -1
	spawned_count = 0
	active_enemies = 0
	call_deferred("_start_next_wave")

func _start_next_wave() -> void:
	if _is_shutting_down:
		_starting = false
		return

	if waves.is_empty():
		push_warning("WaveController has no waves configured.")
		_starting = false
		return

	current_wave_index += 1
	if current_wave_index >= waves.size():
		_starting = false
		waves_completed.emit()
		return

	spawned_count = 0
	active_enemies = 0
	_current_wave_spawn_total = 0
	_current_wave_finished_spawning = false
	_advancing_wave = false

	var wave: Dictionary = waves[current_wave_index]
	var wave_label: String = _get_wave_label(wave, current_wave_index)
	wave_started.emit(current_wave_index, wave_label)
	call_deferred("_spawn_wave", current_wave_index)

func _spawn_wave(wave_index: int) -> void:
	if _is_shutting_down or current_wave_index != wave_index:
		return

	var wave: Dictionary = waves[wave_index]
	var entries: Array = _get_wave_entries(wave)
	for entry_variant in entries:
		if not entry_variant is Dictionary:
			push_warning("Wave %s contains an invalid spawn entry. Skipping it." % _get_wave_label(wave, wave_index))
			continue

		var entry: Dictionary = entry_variant
		var enemy_scene: PackedScene = entry.get("scene", null) as PackedScene
		if enemy_scene == null:
			push_warning("Wave %s references a missing enemy scene. Skipping that entry." % _get_wave_label(wave, wave_index))
			continue

		var count: int = maxi(int(entry.get("count", 0)), 0)
		_current_wave_spawn_total += count

		for spawn_index in range(count):
			if _spawn_enemy(enemy_scene, wave_index, wave):
				spawned_count += 1

			var spawn_delay: float = _get_spawn_interval(entry)
			var is_last_spawn: bool = spawn_index == count - 1
			if spawn_delay > 0.0 and not is_last_spawn:
				await get_tree().create_timer(spawn_delay).timeout

	_current_wave_finished_spawning = true
	_try_finish_current_wave()

func _spawn_enemy(enemy_scene: PackedScene, wave_index: int, wave: Dictionary) -> bool:
	if enemy_scene == null:
		return false

	if player == null:
		push_warning("WaveController cannot spawn enemies without a player reference.")
		return false

	var enemy_instance: Node = enemy_scene.instantiate()
	if enemy_instance == null:
		push_warning("WaveController failed to instantiate an enemy scene.")
		return false

	var spawn_parent: Node = _get_spawn_parent()
	if spawn_parent == null:
		push_warning("WaveController could not find a spawn parent.")
		enemy_instance.queue_free()
		return false

	if enemy_instance is Node2D:
		var enemy_node_2d: Node2D = enemy_instance as Node2D
		var random_angle: float = randf() * TAU
		var spawn_direction: Vector2 = Vector2.RIGHT.rotated(random_angle)
		var spawn_position := player.global_position + (spawn_direction * spawn_radius)
		enemy_node_2d.global_position = _pick_spawn(spawn_position)

	enemy_instance.tree_exited.connect(_on_enemy_removed)
	active_enemies += 1
	spawn_parent.add_child(enemy_instance)
	enemy_spawned.emit(enemy_instance, wave_index, _get_wave_label(wave, wave_index))
	return true

func _get_spawn_parent() -> Node:
	if get_parent() != null:
		return get_parent()

	if get_tree().current_scene != null:
		return get_tree().current_scene

	return null

func _on_enemy_removed() -> void:
	active_enemies = maxi(active_enemies - 1, 0)

	if _is_shutting_down or not is_inside_tree() or get_tree() == null:
		return

	_try_finish_current_wave()

func _try_finish_current_wave() -> void:
	if _advancing_wave or _is_shutting_down:
		return

	if not _current_wave_finished_spawning:
		return

	if active_enemies > 0:
		return

	var wave_index: int = current_wave_index
	if wave_index < 0 or wave_index >= waves.size():
		return

	var wave: Dictionary = waves[wave_index]
	var wave_label: String = _get_wave_label(wave, wave_index)
	_advancing_wave = true
	wave_cleared.emit(wave_index, wave_label)

	var delay: float = _get_inter_wave_delay(wave)
	var tree: SceneTree = get_tree()
	if tree == null:
		return

	if delay > 0.0:
		await tree.create_timer(delay).timeout

		if _is_shutting_down or not is_inside_tree() or get_tree() == null:
			return

	if current_wave_index == wave_index:
		_start_next_wave()

func _get_spawn_interval(entry: Dictionary) -> float:
	var override_delay: float = float(entry.get("spawn_interval", -1.0))
	if override_delay >= 0.0:
		return override_delay

	return default_spawn_interval

func _get_inter_wave_delay(wave: Dictionary) -> float:
	var override_delay: float = float(wave.get("delay", -1.0))
	if override_delay >= 0.0:
		return override_delay

	return inter_wave_delay

func _get_wave_label(wave: Dictionary, wave_index: int) -> String:
	var label: String = str(wave.get("label", ""))
	if label.is_empty():
		return "Wave %d" % (wave_index + 1)

	return label

func _get_wave_entries(wave: Dictionary) -> Array:
	return wave.get("entries", [])
