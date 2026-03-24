extends SceneTree

const STATS_SCRIPT := preload("res://scripts/stats.gd")
const STAT_BUFF_SCRIPT := preload("res://scripts/stat_buff.gd")
const SCORE_MANAGER_SCRIPT := preload("res://scenes/hud/score_manager.gd")

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
	await test_score_manager_emits_updates()
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
