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

	# Never return an empty cell: used_rect can contain "holes" in sparse maps.
	# Try near the desired spawn first (keeps enemies around the player), then fall back to any used cell.
	for _i in range(30):
		var c := Vector2i(
			clamp(base.x + randi_range(-8, 8), minc.x, maxc.x),
			clamp(base.y + randi_range(-8, 8), minc.y, maxc.y)
		)
		if m.get_cell_source_id(c) == -1:
			continue
		var w := m.to_global(m.map_to_local(c))
		if mask != 0:
			var q := PhysicsPointQueryParameters2D.new()
			q.position = w
			q.collision_mask = mask
			q.collide_with_bodies = true
			q.collide_with_areas = false
			q.exclude = exclude
			if not space.intersect_point(q, 1).is_empty():
				continue
		return w

	var used_cells: Array[Vector2i] = []
	if m.has_method("get_used_cells"):
		used_cells = m.get_used_cells()

	if used_cells.is_empty():
		# Fallback for older Godot builds: brute-scan the used_rect for actual tiles.
		for y in range(minc.y, maxc.y + 1):
			for x in range(minc.x, maxc.x + 1):
				var c := Vector2i(x, y)
				if m.get_cell_source_id(c) != -1:
					used_cells.append(c)

	if used_cells.is_empty():
		return desired

	for _j in range(60):
		var c := used_cells[randi() % used_cells.size()]
		var w := m.to_global(m.map_to_local(c))
		if mask != 0:
			var q2 := PhysicsPointQueryParameters2D.new()
			q2.position = w
			q2.collision_mask = mask
			q2.collide_with_bodies = true
			q2.collide_with_areas = false
			q2.exclude = exclude
			if not space.intersect_point(q2, 1).is_empty():
				continue
		return w

	return desired

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
		var spawn_position := player.global_position + (spawn_direction * spawn_radius)
		enemy_2d.global_position = _pick_spawn(spawn_position)

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
