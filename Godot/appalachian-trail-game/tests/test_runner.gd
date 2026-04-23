extends SceneTree

const STATS_SCRIPT := preload("res://scripts/stats.gd")
const STAT_BUFF_SCRIPT := preload("res://scripts/stat_buff.gd")
const SCORE_MANAGER_SCRIPT := preload("res://scenes/hud/score_manager.gd")
const BIGFOOT_BOSS_SCENE := preload("res://scenes/entities/enemies/bigfoot_boss.tscn")
const ROCK_PROJECTILE_SCENE := preload("res://scenes/weapons/rock_projectile.tscn")
const MAIN_SCRIPT := preload("res://scripts/main.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_and_exit")

func run_and_exit() -> void:
	await run_tests()

	if failures.is_empty():
		print("All headless regression tests passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)


func run_tests() -> void:
	test_stats_setup_sets_health_to_max()
	test_leveling_recalculates_stats()
	test_additive_and_multiplicative_buffs_stack()
	await test_bigfoot_walks_to_cover_then_hides()
	await test_bigfoot_attack_patterns_spawn_projectiles()
	test_main_returns_bigfoot_scene_for_boss_wave()
	await test_score_manager_emits_updates()
	await test_score_manager_show_start_screen()
	await test_score_manager_end_game_creates_overlay()


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])


func test_stats_setup_sets_health_to_max() -> void:
	var stats: Stats = STATS_SCRIPT.new()
	stats.base_max_health = 120
	stats.setup_stats()

	assert_equal(stats.health, stats.current_max_health, "Stats setup should sync health with max health.")
	assert_true(stats.current_max_health > 0, "Stats setup should produce a positive max health value.")


func test_leveling_recalculates_stats() -> void:
	var stats: Stats = STATS_SCRIPT.new()
	stats.base_attack = 20
	stats.setup_stats()
	var starting_attack := stats.current_attack

	stats.experience = 1600

	assert_true(stats.level > 1, "Experience should increase the computed level.")
	assert_true(stats.current_attack > starting_attack, "Leveling should increase scaled attack.")


func test_additive_and_multiplicative_buffs_stack() -> void:
	var stats: Stats = STATS_SCRIPT.new()
	stats.base_attack = 10
	stats.setup_stats()
	var starting_attack := stats.current_attack

	var add_buff: StatBuff = STAT_BUFF_SCRIPT.new(Stats.BuffableStats.ATTACK, 5.0, StatBuff.BuffType.ADD)
	var mult_buff: StatBuff = STAT_BUFF_SCRIPT.new(Stats.BuffableStats.ATTACK, 0.5, StatBuff.BuffType.MULTIPLY)

	stats.add_buff(add_buff)
	stats.add_buff(mult_buff)
	stats.recalculate_stats()

	assert_true(stats.current_attack > starting_attack, "Buffed attack should exceed the unbuffed attack.")
	assert_equal(stats.current_attack, int(starting_attack * 1.5 + 5.0), "Attack buffs should apply both additive and multiplicative changes.")


func test_score_manager_emits_updates() -> void:
	var score_manager: Node = SCORE_MANAGER_SCRIPT.new()
	get_root().add_child(score_manager)
	await process_frame

	var received_scores: Array[int] = []
	score_manager.ScoreChanged.connect(func(new_score: int) -> void:
		received_scores.append(new_score)
	)

	score_manager.add_points(7)
	score_manager.add_points(5)

	assert_equal(score_manager.score, 12, "Score manager should accumulate points.")
	assert_equal(received_scores.size(), 2, "Score manager should emit on each score change.")
	assert_equal(received_scores.back(), 12, "Score change signal should publish the latest score.")

	score_manager.queue_free()

func test_score_manager_show_start_screen() -> void:
	var score_manager: Node = SCORE_MANAGER_SCRIPT.new()
	get_root().add_child(score_manager)
	await process_frame

	score_manager.call("show_start_screen")

	assert_true(score_manager.start_screen_node != null, "Start screen should create an overlay.")
	assert_true(score_manager.get_tree().paused, "Start screen should pause the scene tree.")

	score_manager.call("_clear_start_screen")
	await process_frame

	assert_true(score_manager.start_screen_node == null, "Clearing the start screen should remove the overlay.")
	assert_true(not score_manager.get_tree().paused, "Clearing the start screen should unpause the scene tree.")

	score_manager.queue_free()


func test_score_manager_end_game_creates_overlay() -> void:
	var score_manager: Node = SCORE_MANAGER_SCRIPT.new()
	get_root().add_child(score_manager)
	await process_frame
	score_manager.add_points(9)
	score_manager.end_game()

	assert_true(score_manager.end_screen_node != null, "Ending the game should create an end screen overlay.")
	assert_true(score_manager.get_tree().paused, "Ending the game should pause the scene tree.")

	score_manager.get_tree().paused = false
	score_manager.queue_free()


func test_bigfoot_walks_to_cover_then_hides() -> void:
	var arena := Node2D.new()
	get_root().add_child(arena)

	var player := Node2D.new()
	player.name = "Player"
	player.global_position = Vector2(0, 0)
	arena.add_child(player)

	for point in [Vector2(120, 0), Vector2(-140, 40)]:
		var marker := Marker2D.new()
		marker.global_position = point
		marker.add_to_group("boss_tree_cover")
		arena.add_child(marker)

	var boss: CharacterBody2D = BIGFOOT_BOSS_SCENE.instantiate() if BIGFOOT_BOSS_SCENE != null else null
	if boss == null:
		failures.append("test_bigfoot_walks_to_cover_then_hides: Boss scene failed to load.")
		return
	boss.global_position = Vector2(0, 0)
	boss.set("move_speed", 320.0)
	boss.set("hide_duration", 0.2)
	arena.add_child(boss)

	for _i in range(45):
		await process_frame

	var state: int = boss.get("state")
	assert_true(state != boss.BossState.WALK_TO_FIRST_TREE, "Boss should reach the first tree and leave WALK_TO_FIRST_TREE.")

	boss.queue_free()
	arena.queue_free()
	await process_frame


func test_bigfoot_attack_patterns_spawn_projectiles() -> void:
	var arena := Node2D.new()
	get_root().add_child(arena)

	var player := Node2D.new()
	player.name = "Player"
	player.global_position = Vector2(250, 0)
	arena.add_child(player)

	var marker := Marker2D.new()
	marker.global_position = Vector2(0, 0)
	marker.add_to_group("boss_tree_cover")
	arena.add_child(marker)

	var boss: CharacterBody2D = BIGFOOT_BOSS_SCENE.instantiate()
	boss.global_position = Vector2(0, 0)
	arena.add_child(boss)
	await process_frame

	var before_count: int = _count_nodes_by_scene_path("res://scenes/weapons/rock_projectile.tscn")
	boss.call("_fire_boulder")
	await process_frame
	var after_boulder_count: int = _count_nodes_by_scene_path("res://scenes/weapons/rock_projectile.tscn")

	assert_equal(after_boulder_count, before_count + 1, "Boulder attack should spawn exactly one projectile.")

	boss.set("split_shot_count", 5)
	boss.call("_fire_split_shot")
	await process_frame
	var after_split_count: int = _count_nodes_by_scene_path("res://scenes/weapons/rock_projectile.tscn")

	assert_equal(after_split_count, after_boulder_count + 5, "Split shot should spawn the configured projectile count.")

	_clear_projectiles()
	boss.queue_free()
	arena.queue_free()
	await process_frame


func test_main_returns_bigfoot_scene_for_boss_wave() -> void:
	var main_script_instance := MAIN_SCRIPT.new()
	var boss_scene: PackedScene = main_script_instance.call("_get_boss_scene")

	assert_true(boss_scene != null, "Main should provide a boss scene for boss wave entries.")
	assert_equal(boss_scene.resource_path, BIGFOOT_BOSS_SCENE.resource_path, "Boss wave should use the Bigfoot boss scene.")


func _count_nodes_by_scene_path(scene_path: String) -> int:
	var count: int = 0
	for node_variant in get_root().get_children():
		var node := node_variant as Node
		if node == null:
			continue
		for child_variant in node.get_children():
			var child := child_variant as Node
			if child == null:
				continue
			var child_scene_path: String = child.scene_file_path
			if child_scene_path == scene_path:
				count += 1
	return count


func _clear_projectiles() -> void:
	for node_variant in get_root().get_children():
		var node := node_variant as Node
		if node == null:
			continue
		for child_variant in node.get_children():
			var child := child_variant as Node
			if child == null:
				continue
			if child.scene_file_path == ROCK_PROJECTILE_SCENE.resource_path:
				child.queue_free()
