extends Node2D
@export var enemy_scene: PackedScene
@export var player: Node2D
@export var enemies_to_spawn: int = 20
@export var spawn_radius: float = 800.0
@export var spawn_interval: float = 1.5
var spawned_count: int = 0
var active_enemies: int = 0
var timer: Timer
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
		ScoreManager.end_game()
