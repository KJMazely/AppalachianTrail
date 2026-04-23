extends Node2D
@export var enemy_scene: PackedScene
@export var player: Node2D
@export var enemies_to_spawn: int = 20
@export var spawn_radius: float = 800.0
@export var spawn_interval: float = 1.5
var spawned_count: int = 0
var active_enemies: int = 0
var timer: Timer

func _map() -> TileMapLayer:
	var s := get_tree().current_scene
	if s == null:
		return null

	var direct := s.get_node_or_null("TileMapLayer") as TileMapLayer
	if direct != null:
		return direct

	var found := s.find_children("*", "TileMapLayer", true, false)
	return found[0] as TileMapLayer if not found.is_empty() else null

func _pick_spawn(desired: Vector2) -> Vector2:
	var m := _map(); if m == null: return desired
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
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()
func _on_timer_timeout() -> void:
	if spawned_count >= enemies_to_spawn:
		timer.stop()
		return
	spawn_enemy()
func spawn_enemy() -> void:
	if not player or not enemy_scene:
		return
	var random_angle = randf() * TAU
	var spawn_direction = Vector2.RIGHT.rotated(random_angle)
	var spawn_position = player.global_position + (spawn_direction * spawn_radius)
	spawn_position = _pick_spawn(spawn_position)
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = spawn_position
	# Connect the enemy's "death" (removal from tree) to a function
	enemy_instance.tree_exited.connect(_on_enemy_removed)
	# Increase the count of active enemies
	active_enemies += 1
	get_tree().current_scene.add_child(enemy_instance)
	spawned_count += 1
	
# function runs every time an enemy is queue_free()'d
func _on_enemy_removed():
	active_enemies -= 1
	# Check if we have finished spawning all enemies 
	# check if the last one just died
	if spawned_count >= enemies_to_spawn and active_enemies <= 0:
		var score_manager := get_node_or_null("/root/ScoreManager")
		if score_manager != null:
			score_manager.call("end_game")
