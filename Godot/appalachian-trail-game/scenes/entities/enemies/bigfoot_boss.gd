extends CharacterBody2D

enum BossState {
	WALK_TO_FIRST_TREE,
	OPENING_TELEPORTS,
	HIDDEN_BEHIND_TREE,
	PEEKING,
	ATTACKING,
	TELEPORTING,
	WALKING_TO_COVER,
	RELOCATE,
	DEAD,
}

@export_group("Boss Stats")
@export var stats: Stats
@export var move_speed: float = 150.0
@export var friction: float = 900.0
@export var score_value: int = 50

@export_group("Rock Throw")
@export var rock_scene: PackedScene = preload("res://scenes/weapons/rock_projectile.tscn")
@export var throw_range: float = 900.0
@export var attack_cooldown: float = 1.0

@export_group("Attack Pattern")
@export var boulder_speed: float = 280.0
@export var boulder_attack_value: int = 8
@export var pebble_speed: float = 420.0
@export var pebble_attack_value: int = 4
@export var split_shot_count: int = 5
@export var split_shot_spread_degrees: float = 36.0

@export_group("Cover Movement")
@export var relocate_delay: float = 1.0
@export var hide_duration: float = 0.6
@export var peek_duration: float = 0.45
@export var cover_arrival_distance: float = 18.0
@export var min_cover_distance: float = 120.0
@export var max_cover_distance: float = 99999.0
@export var cover_group: StringName = &"boss_tree_cover"
@export var hide_offset: Vector2 = Vector2(0.0, 14.0)
@export var peek_offset: Vector2 = Vector2(0.0, -20.0)

@export_group("Opening Teleports")
@export var opening_teleport_min: int = 2
@export var opening_teleport_max: int = 4
@export var opening_teleport_delay: float = 0.25

@export_group("Relocation Walking")
@export var walk_relocate_chance: float = 0.5

@export_group("Audio")
@export var hurt_sound: AudioStream
@export var throw_sound: AudioStream
@export var death_sound: AudioStream

var state: BossState = BossState.WALK_TO_FIRST_TREE
var _cover_points: Array[Node2D] = []
var _current_cover: Node2D
var _target_cover: Node2D
var _state_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _initialized_cover_walk: bool = false
var _opening_teleports_left: int = 0

@onready var player: Node2D = $"../Player"
@onready var sprite: Node2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var death_effect_scene: PackedScene = preload("res://scenes/entities/enemies/Death.tscn")

func _ready() -> void:
	if stats:
		stats = stats.duplicate()
		stats.setup_stats()
		if not stats.health_depleted.is_connected(_on_death):
			stats.health_depleted.connect(_on_death)

	_refresh_cover_points()
	_spawn_at_random_cover()

func _physics_process(delta: float) -> void:
	if state == BossState.DEAD:
		return

	if not is_instance_valid(player):
		player = get_node_or_null("../Player")

	match state:
		BossState.WALK_TO_FIRST_TREE:
			_process_walk_to_first_tree(delta)
		BossState.OPENING_TELEPORTS:
			_process_opening_teleports(delta)
		BossState.HIDDEN_BEHIND_TREE:
			_process_hidden_state(delta)
		BossState.PEEKING:
			_process_peeking_state(delta)
		BossState.ATTACKING:
			_process_attacking_state(delta)
		BossState.TELEPORTING:
			_process_teleporting_state()
		BossState.WALKING_TO_COVER:
			_process_walking_to_cover(delta)
		BossState.RELOCATE:
			_process_relocate(delta)

	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, friction * delta)

func _process_walk_to_first_tree(delta: float) -> void:
	if not is_instance_valid(_target_cover):
		_pick_initial_cover()
		if not is_instance_valid(_target_cover):
			_process_fallback_attack()
			return

	_move_toward_position(_get_hide_position(_target_cover), delta)

	if global_position.distance_to(_get_hide_position(_target_cover)) <= cover_arrival_distance:
		velocity = _knockback_velocity
		move_and_slide()
		_current_cover = _target_cover
		global_position = _get_hide_position(_current_cover)
		_set_state(BossState.HIDDEN_BEHIND_TREE, hide_duration)

func _spawn_at_random_cover() -> void:
	if _cover_points.is_empty():
		_refresh_cover_points()

	if _cover_points.is_empty():
		_process_fallback_attack()
		return

	var start_cover: Node2D = _cover_points[randi() % _cover_points.size()]
	_current_cover = start_cover
	_target_cover = null
	global_position = _get_hide_position(_current_cover)

	var min_count := maxi(opening_teleport_min, 0)
	var max_count := maxi(opening_teleport_max, min_count)
	_opening_teleports_left = randi_range(min_count, max_count)
	if _opening_teleports_left > 0:
		_set_state(BossState.OPENING_TELEPORTS, opening_teleport_delay)
	else:
		_set_state(BossState.HIDDEN_BEHIND_TREE, hide_duration)

func _process_opening_teleports(delta: float) -> void:
	velocity = _knockback_velocity
	move_and_slide()

	_state_timer -= delta
	if _state_timer > 0.0:
		return

	if _opening_teleports_left <= 0:
		_set_state(BossState.HIDDEN_BEHIND_TREE, hide_duration)
		return

	_pick_next_cover()
	if is_instance_valid(_target_cover):
		_current_cover = _target_cover
		global_position = _get_hide_position(_current_cover)

	_opening_teleports_left -= 1
	_set_state(BossState.OPENING_TELEPORTS, opening_teleport_delay)

func _process_hidden_state(delta: float) -> void:
	velocity = _knockback_velocity
	move_and_slide()
	_state_timer -= delta
	if _state_timer <= 0.0:
		_set_state(BossState.PEEKING, peek_duration)

func _process_peeking_state(delta: float) -> void:
	if not is_instance_valid(_current_cover):
		_set_state(BossState.TELEPORTING, 0.0)
		return

	_move_toward_position(_get_peek_position(_current_cover), delta)
	_state_timer -= delta

	if _state_timer <= 0.0:
		_set_state(BossState.ATTACKING, 0.0)

func _process_attacking_state(_delta: float) -> void:
	velocity = _knockback_velocity
	move_and_slide()

	if not player:
		_set_state(BossState.RELOCATE, relocate_delay)
		return

	if global_position.distance_to(player.global_position) > throw_range:
		_set_state(BossState.HIDDEN_BEHIND_TREE, hide_duration)
		return

	_face_toward(player.global_position)
	if randf() < 0.5:
		_fire_boulder()
	else:
		_fire_split_shot()

	var next_relocate_delay := maxf(relocate_delay, attack_cooldown)
	_set_state(BossState.RELOCATE, next_relocate_delay)

func _process_teleporting_state() -> void:
	_pick_next_cover()
	if is_instance_valid(_target_cover):
		_current_cover = _target_cover
		global_position = _get_hide_position(_current_cover)
		_set_state(BossState.HIDDEN_BEHIND_TREE, hide_duration)
	else:
		_set_state(BossState.ATTACKING, 0.0)

func _process_walking_to_cover(delta: float) -> void:
	if not is_instance_valid(_target_cover):
		_pick_next_cover()
		if not is_instance_valid(_target_cover):
			_set_state(BossState.ATTACKING, 0.0)
			return

	_move_toward_position(_get_hide_position(_target_cover), delta)

	if global_position.distance_to(_get_hide_position(_target_cover)) <= cover_arrival_distance:
		velocity = _knockback_velocity
		move_and_slide()
		_current_cover = _target_cover
		global_position = _get_hide_position(_current_cover)
		_set_state(BossState.HIDDEN_BEHIND_TREE, hide_duration)

func _process_relocate(delta: float) -> void:
	velocity = _knockback_velocity
	move_and_slide()

	_state_timer -= delta
	if _state_timer > 0.0:
		return

	if randf() < clampf(walk_relocate_chance, 0.0, 1.0):
		_pick_next_cover()
		_set_state(BossState.WALKING_TO_COVER, 0.0)
	else:
		_set_state(BossState.TELEPORTING, 0.0)

func _process_fallback_attack() -> void:
	state = BossState.ATTACKING

func _refresh_cover_points() -> void:
	_cover_points.clear()
	var candidates: Array[Node] = get_tree().get_nodes_in_group(cover_group)
	for node in candidates:
		if node is Node2D:
			_cover_points.append(node as Node2D)

func _pick_initial_cover() -> void:
	if _initialized_cover_walk:
		return
	_initialized_cover_walk = true
	_pick_next_cover()

func _pick_next_cover() -> void:
	if _cover_points.is_empty():
		_refresh_cover_points()
	if _cover_points.is_empty():
		_target_cover = null
		return

	var valid_covers: Array[Node2D] = []
	for cover in _cover_points:
		if not is_instance_valid(cover):
			continue
		if cover == _current_cover:
			continue
		var distance := global_position.distance_to(cover.global_position)
		if distance < min_cover_distance or distance > max_cover_distance:
			continue
		valid_covers.append(cover)

	if valid_covers.is_empty():
		for cover in _cover_points:
			if is_instance_valid(cover) and cover != _current_cover:
				valid_covers.append(cover)

	if valid_covers.is_empty():
		_target_cover = _current_cover
		return

	_target_cover = valid_covers[randi() % valid_covers.size()]

func _fire_boulder() -> void:
	if not rock_scene or not player:
		return

	var rock := rock_scene.instantiate()
	if rock == null:
		return

	rock.stats = stats
	rock.global_position = global_position + Vector2(0.0, -18.0)
	rock.speed = boulder_speed
	rock.projectile_attack = boulder_attack_value
	rock.projectile_size_scale = 1.8
	rock.set_direction(global_position.direction_to(player.global_position))
	get_tree().root.add_child(rock)
	_play_sound(throw_sound)

func _fire_split_shot() -> void:
	if not rock_scene or not player:
		return

	var base_direction: Vector2 = global_position.direction_to(player.global_position)
	var half_spread: float = split_shot_spread_degrees * 0.5
	var steps: int = maxi(split_shot_count - 1, 1)

	for i in range(split_shot_count):
		var t: float = float(i) / float(steps)
		var offset_degrees: float = lerpf(-half_spread, half_spread, t)
		var shot_direction: Vector2 = base_direction.rotated(deg_to_rad(offset_degrees))
		var pebble := rock_scene.instantiate()
		if pebble == null:
			continue

		pebble.stats = stats
		pebble.global_position = global_position + Vector2(0.0, -16.0)
		pebble.speed = pebble_speed
		pebble.projectile_attack = pebble_attack_value
		pebble.projectile_size_scale = 0.8
		pebble.set_direction(shot_direction)
		get_tree().root.add_child(pebble)

	_play_sound(throw_sound)

func _move_toward_position(target_position: Vector2, _delta: float) -> void:
	var direction := global_position.direction_to(target_position)
	_face_toward(target_position)
	velocity = (direction * move_speed) + _knockback_velocity
	move_and_slide()

func _face_toward(target_position: Vector2) -> void:
	var direction_x := target_position.x - global_position.x
	if not (sprite is Sprite2D):
		return

	var sprite_2d := sprite as Sprite2D
	if direction_x < 0.0:
		sprite_2d.flip_h = true
	elif direction_x > 0.0:
		sprite_2d.flip_h = false

func _get_hide_position(cover: Node2D) -> Vector2:
	return cover.global_position + hide_offset

func _get_peek_position(cover: Node2D) -> Vector2:
	return cover.global_position + peek_offset

func _set_state(next_state: BossState, timer: float) -> void:
	state = next_state
	_state_timer = maxf(timer, 0.0)

func handle_hit(hitter_position: Vector2) -> void:
	flash_red()
	if state == BossState.DEAD:
		return

	var knockback_dir := (global_position - hitter_position).normalized()
	_knockback_velocity = knockback_dir * 400.0
	_play_sound(hurt_sound)

func _on_death() -> void:
	state = BossState.DEAD
	ScoreManager.add_points(score_value)

	if death_effect_scene:
		var death_effect := death_effect_scene.instantiate()
		death_effect.global_position = global_position
		get_parent().add_child(death_effect)

	if death_sound:
		var temp_audio := AudioStreamPlayer2D.new()
		temp_audio.stream = death_sound
		temp_audio.global_position = global_position
		get_tree().root.add_child(temp_audio)
		temp_audio.play()
		temp_audio.finished.connect(temp_audio.queue_free)

	queue_free()

func flash_red() -> void:
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _play_sound(stream: AudioStream) -> void:
	if stream and audio_player:
		audio_player.stream = stream
		audio_player.play()
