extends CharacterBody2D

enum State {
	IDLE,
	MOVING,
	ATTACK,
	DEAD
}

@export_group("Movement Settings")
@export var stats: Stats
@export var speed: float = 120.0
@export var knockback_force: float = 600.0
@export var friction: float = 1500.0

@export_group("Combat Settings")
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.0
@export var hitbox_lifetime: float = 0.2

@export_group("Ranged Settings")
@export var can_shoot: bool = false
@export var shoot_range: float = 200.0
@export var shoot_cooldown: float = 2.0
@export var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")
@export var projectile_speed: float = 500.0
@export var projectile_texture: Texture2D
@export var projectile_size_scale: float = 1.0

@export_group("Audio Settings")
@export var hurt_sound: AudioStream
@export var attack_sound: AudioStream
@export var shoot_sound: AudioStream
@export var death_sound: AudioStream
@export var audio_cooldown: float = 0.4 

var state: State = State.IDLE
var knockback_velocity: Vector2 = Vector2.ZERO
var can_attack: bool = true
var ready_to_shoot: bool = true

# NEW: Tracks if the enemy is allowed to play a sound right now
var can_play_audio: bool = true 

@onready var deathsprite = preload("res://scenes/entities/enemies/Death.tscn")

@onready var player: Node2D = get_node_or_null("../Player") as Node2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	if stats:
		stats = stats.duplicate()
		stats.setup_stats()
		stats.health_depleted.connect(_on_death)
		print("Enemy: Stats connected for ", name)
	
	animation_tree.active = true

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	var direction = Vector2.ZERO
	var distance_to_player = 9999.0
	
	if player:
		direction = global_position.direction_to(player.global_position)
		distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_range and can_attack and state != State.ATTACK:
		perform_attack()
	elif can_shoot and distance_to_player <= shoot_range and ready_to_shoot and state != State.ATTACK:
		perform_shoot()

	if state != State.ATTACK:
		var move_velocity = direction * speed
		velocity = move_velocity + knockback_velocity
		
		if direction.x < 0:
			sprite.flip_h = true
		elif direction.x > 0:
			sprite.flip_h = false

		move_and_slide()
		update_state()
	else:
		velocity = knockback_velocity
		move_and_slide()
	
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction * delta)

func perform_attack() -> void:
	state = State.ATTACK
	can_attack = false
	
	play_sound(attack_sound)
	spawn_hitbox()
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
	if state != State.DEAD:
		state = State.IDLE

func perform_shoot() -> void:
	state = State.ATTACK
	ready_to_shoot = false
	
	play_sound(shoot_sound)
	spawn_bullet()
	
	await get_tree().create_timer(0.3).timeout
	
	if state != State.DEAD:
		state = State.IDLE
		
	var remaining_cooldown = max(0.0, shoot_cooldown - 0.3)
	if remaining_cooldown > 0:
		await get_tree().create_timer(remaining_cooldown).timeout
		
	ready_to_shoot = true

func spawn_hitbox() -> void:
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = attack_range
	var attack_hitbox = Hitbox.new(stats, hitbox_lifetime, attack_shape, null)
	add_child(attack_hitbox)

func spawn_bullet() -> void:
	if not bullet_scene or not player:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.stats = stats 
	if "speed" in bullet:
		bullet.speed = projectile_speed
	var dir_to_player = global_position.direction_to(player.global_position)
	bullet.set_direction(dir_to_player)
	_apply_projectile_overrides(bullet)
	_keep_projectile_visual_upright(bullet)
	
	get_tree().root.add_child(bullet)
	bullet.global_position = global_position

func _apply_projectile_overrides(projectile: Node) -> void:
	if projectile_texture:
		var projectile_sprite := projectile.get_node_or_null("Sprite2D") as Sprite2D
		if projectile_sprite:
			projectile_sprite.texture = projectile_texture

		var projectile_body_sprite := projectile.get_node_or_null("ProjectileBody") as Sprite2D
		if projectile_body_sprite:
			projectile_body_sprite.texture = projectile_texture

	if is_equal_approx(projectile_size_scale, 1.0):
		return

	var scaled_shape := projectile.get("damage_shape") as Shape2D
	if scaled_shape:
		projectile.set("damage_shape", _scale_shape(scaled_shape, projectile_size_scale))

	var collision_shape := projectile.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape and collision_shape.shape:
		collision_shape.shape = _scale_shape(collision_shape.shape, projectile_size_scale)

	var projectile_sprite_node := projectile.get_node_or_null("Sprite2D") as Node2D
	if projectile_sprite_node:
		projectile_sprite_node.scale *= projectile_size_scale

	var projectile_body_node := projectile.get_node_or_null("ProjectileBody") as Node2D
	if projectile_body_node:
		projectile_body_node.scale *= projectile_size_scale

func _keep_projectile_visual_upright(projectile: Node) -> void:
	var projectile_sprite := projectile.get_node_or_null("Sprite2D") as Node2D
	if projectile_sprite:
		projectile_sprite.rotation = -projectile.rotation

	var projectile_body := projectile.get_node_or_null("ProjectileBody") as Node2D
	if projectile_body:
		projectile_body.rotation = -projectile.rotation

func _scale_shape(shape: Shape2D, amount: float) -> Shape2D:
	var scaled_shape := shape.duplicate()

	if scaled_shape is CircleShape2D:
		(scaled_shape as CircleShape2D).radius *= amount
	elif scaled_shape is RectangleShape2D:
		(scaled_shape as RectangleShape2D).size *= amount
	elif scaled_shape is CapsuleShape2D:
		(scaled_shape as CapsuleShape2D).radius *= amount
		(scaled_shape as CapsuleShape2D).height *= amount

	return scaled_shape

func handle_hit(hitter_position: Vector2) -> void:
	if state == State.DEAD:
		return
		
	play_sound(hurt_sound)
	flash_red()
	var knockback_direction = (global_position - hitter_position).normalized()
	knockback_velocity = knockback_direction * knockback_force

func flash_red() -> void:
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func update_state() -> void:
	if state == State.ATTACK: return
	
	if velocity.length() > 10.0:
		if state != State.MOVING:
			state = State.MOVING
			animation_playback.travel("moving")
	else:
		if state != State.IDLE:
			state = State.IDLE
			animation_playback.travel("idle")

func _on_death() -> void:
	state = State.DEAD
	var score_manager := get_node_or_null("/root/ScoreManager")
	if score_manager != null:
		score_manager.call("add_points", 5)

	var deathsprite_instance = deathsprite.instantiate()
	deathsprite_instance.global_position = global_position
	get_parent().add_child(deathsprite_instance)

	if death_sound and death_sound.get_class() != "AudioStream":
		var temp_audio = AudioStreamPlayer2D.new()
		temp_audio.stream = death_sound
		temp_audio.global_position = global_position
		get_tree().root.add_child(temp_audio)
		temp_audio.play()
		temp_audio.finished.connect(temp_audio.queue_free)

	queue_free()

# UPDATED: Added Timer Logic
func play_sound(stream: AudioStream) -> void:
	# Only play if we have a stream, the player exists, AND the audio cooldown is finished
	if stream != null and stream.get_class() != "AudioStream" and audio_player != null and can_play_audio:
		audio_player.stream = stream
		audio_player.play()
		
		# Lock the audio so it can't be spammed
		can_play_audio = false
		
		# Wait for the cooldown timer to finish
		await get_tree().create_timer(audio_cooldown).timeout
		
		# Ensure the enemy hasn't been deleted or killed while we were waiting
		if is_instance_valid(self) and state != State.DEAD:
			can_play_audio = true
