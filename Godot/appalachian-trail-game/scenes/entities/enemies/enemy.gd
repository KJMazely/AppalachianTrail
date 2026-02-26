extends CharacterBody2D

enum State {
	IDLE,
	MOVING,
	ATTACK,
	DEAD
}

@export var stats: Stats
@export var hitpoints: int = 180
@export var speed: float = 150.0
@export var knockback_force: float = 300.0
@export var flash_time: float = 0.1

@export var hurtbox_shape: Shape2D

var state: State = State.IDLE
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var player = $"../Player"
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = \
	$AnimationTree["parameters/playback"]


func _ready() -> void:
	animation_tree.active = true


# 🔥 CALLED BY THE BULLET
func get_damage(damage_taken: int) -> void:
	if state == State.DEAD:
		return

	hitpoints -= damage_taken
	flash_red()
	apply_knockback()

	if hitpoints <= 0:
		death()


# 💥 Knockback away from the player (or bullet direction)
func apply_knockback() -> void:
	if player:
		var direction = (global_position - player.global_position).normalized()
		knockback_velocity = direction * knockback_force


# 🔴 Flash red effect
func flash_red() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(flash_time).timeout
	sprite.modulate = Color.WHITE


func death() -> void:
	state = State.DEAD
	queue_free()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if player:
		var direction = global_position.direction_to(player.global_position)

		# Apply knockback first, then decay it
		velocity = direction * speed + knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)

		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false

		move_and_slide()

		update_state()


func update_state() -> void:
	if velocity != Vector2.ZERO and state == State.IDLE:
		state = State.MOVING
		update_animation()
	elif velocity == Vector2.ZERO and state == State.MOVING:
		state = State.IDLE
		update_animation()


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.MOVING:
			animation_playback.travel("moving")
		State.ATTACK:
			animation_playback.travel("attack")


func _on_hurtbox_died() -> void:
	sprite.play("die")


func _on_hurtbox_hurt() -> void:
	sprite.play("hurt")
