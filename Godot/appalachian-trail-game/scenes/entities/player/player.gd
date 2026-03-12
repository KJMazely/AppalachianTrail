extends CharacterBody2D

enum State {
	IDLE,
	MOVING,
	ATTACK,
	DEAD
}

@export var stats:Stats
@export var speed: int = 400
@export var attack_speed: float = 1.0
@export var knockback_force: float = 600.0
@export var friction: float = 1500.0 # How fast the player stops sliding after being hit


var knockback_velocity: Vector2 = Vector2.ZERO
var state: State = State.IDLE
var get_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var gun = $Gun
@onready var sprite: Sprite2D = $Sprite2D
const offset = 1



func _ready() -> void:
	if stats:
		stats.setup_stats()
		
		# Connect the signal
		stats.health_depleted.connect(_on_death)
		print("Player: Stats connected for ", name)
	
	animation_tree.active = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()
		

func _physics_process(delta):
	movement_loop()
	

func movement_loop() -> void:
	
	get_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	get_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	var motion: Vector2 = get_direction.normalized() * speed
	set_velocity(motion)
	velocity = motion + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction )
	

	if get_direction != Vector2.ZERO:
		gun.setup_direction(get_direction)
	
	move_and_slide()
	
	#sprite flip
	if state == State.IDLE or State.MOVING:
		if get_direction.x < -0.01:
			$Sprite2D.flip_h = true
			$Gun.position.x = 16
		elif get_direction.x > 0.01:
			$Sprite2D.flip_h = false
			$Gun.position.x = -16

	# sprite animation
	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.MOVING
		update_animation()
	elif motion == Vector2.ZERO and state == State.MOVING:
		state = State.IDLE
		update_animation()


func update_animation():
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.MOVING:
			animation_playback.travel("moving")
		State.ATTACK:
			animation_playback.travel("attack")


func attack() -> void:
	#make sure player isnt already attacking
	if state == State.ATTACK:
		return
	gun.shoot()
	update_animation()
	
	#Return to idle state after attack anim is done
	state = State.IDLE

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

func _on_death() -> void:
	print("Plyer: _on_death called for ", name)
	state = State.DEAD
	queue_free()
	ScoreManager.end_game()
