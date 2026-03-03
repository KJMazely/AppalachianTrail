extends CharacterBody2D

enum State {
	IDLE,
	MOVING,
	ATTACK,
	DEAD
}

@export var stats: Stats
@export var speed: float = 120.0
@export var knockback_force: float = 600.0
@export var friction: float = 1500.0 # How fast the enemy stops sliding after being hit

var state: State = State.IDLE
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var player = $"../Player"
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready() -> void:
	# 1. Essential: Duplicate the stats resource so enemies don't share health
	if stats:
		stats = stats.duplicate()
		stats.setup_stats()
		stats.health_depleted.connect(_on_death)
	
	animation_tree.active = true

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	# 2. Handle Movement Logic
	var direction = Vector2.ZERO
	
	if player:
		direction = global_position.direction_to(player.global_position)
	
	# 3. Combine Normal Velocity and Knockback Velocity
	# We use move_toward to slowly reduce knockback to zero via friction
	var move_velocity = direction * speed
	velocity = move_velocity + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction * delta)

	# 4. Sprite flipping logic
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

	move_and_slide()
	update_state()

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
	# Creates a quick flash effect using a Tween
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func update_state() -> void:
	# Simple state switching based on movement
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
	# You can add a death animation travel here:
	# animation_playback.travel("death") 
	# Or just delete the enemy:
	queue_free()
