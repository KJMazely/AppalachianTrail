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
@export var friction: float = 1500.0 # How fast the enemy stops sliding after being hit

@export_group("Combat Settings")
@export var attack_range: float = 60.0    # How close the player needs to be to trigger a hit
@export var attack_cooldown: float = 1.0  # Time between attacks
@export var hitbox_lifetime: float = 0.2  # How long the "flash" lasts

var state: State = State.IDLE
var knockback_velocity: Vector2 = Vector2.ZERO
var can_attack: bool = true
@onready var deathsprite = preload("res://scenes/entities/enemies/Death.tscn")

@onready var player = $"../Player"
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready() -> void:
	if stats:
		# Duplicate so each enemy has its own health
		stats = stats.duplicate()
		stats.setup_stats()
		
		# Connect the signal
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
	
	# 1. Attack Check: If within range, stop moving and attack
	if distance_to_player <= attack_range and can_attack and state != State.ATTACK:
		perform_attack()

	# 2. Movement Logic: Only move if not in the middle of an attack
	if state != State.ATTACK:
		var move_velocity = direction * speed
		velocity = move_velocity + knockback_velocity
		
		# Sprite flipping logic
		if direction.x < 0:
			sprite.flip_h = true
		elif direction.x > 0:
			sprite.flip_h = false

		move_and_slide()
		update_state()
	else:
		# While attacking, we don't move normally, but we still apply knockback friction
		velocity = knockback_velocity
		move_and_slide()
	
	# Always decay knockback velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction * delta)

func perform_attack() -> void:
	state = State.ATTACK
	can_attack = false
	
	# Play attack animation
	#animation_playback.travel("attack")
	
	# Create the visual Hitbox
	spawn_hitbox()
	
	# Attack Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
	# Return to idle/moving state after cooldown if not dead
	if state != State.DEAD:
		state = State.IDLE

func spawn_hitbox() -> void:
	# Define a circular shape for the attack
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = attack_range
	
	# Instance the Hitbox (using your Hitbox class)
	# Constructor signature: (_attacker_stats, _hitbox_lifetime, _shape, _hitlog)
	var attack_hitbox = Hitbox.new(stats, hitbox_lifetime, attack_shape, null)
	
	# Add it as a child. It will automatically handle collision masks and queue_free
	add_child(attack_hitbox)

# This function is called by the Hurtbox script when a hit is registered
func handle_hit(hitter_position: Vector2) -> void:
	if state == State.DEAD:
		return
		
	# Trigger the visual flash
	flash_red()
	
	# Calculate knockback direction (away from the bullet/attacker)
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
	ScoreManager.add_points(5)

	var deathsprite = deathsprite.instantiate()
	deathsprite.global_position = global_position
	get_parent().add_child(deathsprite)

	queue_free() # optional, remove enemy
