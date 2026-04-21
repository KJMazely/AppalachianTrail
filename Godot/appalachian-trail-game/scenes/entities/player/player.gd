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

# NEW: Audio Settings
@export_group("Audio Settings")
@export var shoot_sound: AudioStream
@export var move_sound: AudioStream
@export var hurt_sound: AudioStream

# NEW: Cooldown timers so sounds don't overlap/spam
@export var move_audio_cooldown: float = 0.35 # Time between footsteps
@export var hurt_audio_cooldown: float = 0.4  # Invincibility/hurt sound cooldown

var knockback_velocity: Vector2 = Vector2.ZERO
var state: State = State.IDLE
var get_direction: Vector2 = Vector2.ZERO

# NEW: Track if we are allowed to play the sounds right now
var can_play_move: bool = true
var can_play_hurt: bool = true

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var gun = $Gun
@onready var sprite: Sprite2D = $Sprite2D

# NEW: References to our 3 new Audio Players
@onready var shoot_audio: AudioStreamPlayer2D = $ShootAudio
@onready var move_audio: AudioStreamPlayer2D = $MoveAudio
@onready var hurt_audio: AudioStreamPlayer2D = $HurtAudio

const offset = 1

func _ready() -> void:
	if stats:
		stats.setup_stats()
		
		# Connect the death signal
		stats.health_depleted.connect(_on_death)
		
		# Connect health changes to the ScoreManager
		stats.health_changed.connect(ScoreManager.set_health)
		
		# Initialize the health immediately on load
		ScoreManager.set_health(stats.health, stats.current_max_health)
		
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
		# NEW: Play movement/footstep sound while moving
		play_move_sound()
	
	move_and_slide()
	
	#sprite flip
	if state == State.IDLE or state == State.MOVING:
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
	# Make sure player isnt already attacking
	if state == State.ATTACK:
		return
	
	# NEW: Store the true/false result from the gun
	var successfully_fired = gun.shoot()
	
	# Only play the sound if the gun actually spawned a bullet
	if successfully_fired == true:
		play_shoot_sound()
	
	update_animation()
	
	# Return to idle state after attack anim is done
	state = State.IDLE

func handle_hit(hitter_position: Vector2) -> void:
	if state == State.DEAD:
		return
		
	# NEW: Play hurt sound
	play_hurt_sound()
		
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
	print("Player: _on_death called for ", name)
	state = State.DEAD
	queue_free()
	ScoreManager.end_game("lose", false)


# --- NEW: AUDIO HELPER FUNCTIONS ---

func play_shoot_sound() -> void:
	# Guns usually don't need a heavy cooldown timer since the attack speed handles it naturally
	if shoot_sound and shoot_sound.get_class() != "AudioStream" and shoot_audio:
		shoot_audio.stream = shoot_sound
		shoot_audio.play()

func play_move_sound() -> void:
	if move_sound and move_sound.get_class() != "AudioStream" and move_audio and can_play_move:
		move_audio.stream = move_sound
		move_audio.play()
		can_play_move = false
		
		# Wait for the footstep timer
		await get_tree().create_timer(move_audio_cooldown).timeout
		
		if is_instance_valid(self):
			can_play_move = true

func play_hurt_sound() -> void:
	if hurt_sound and hurt_sound.get_class() != "AudioStream" and hurt_audio and can_play_hurt:
		hurt_audio.stream = hurt_sound
		hurt_audio.play()
		can_play_hurt = false
		
		# Wait for the hurt timer
		await get_tree().create_timer(hurt_audio_cooldown).timeout
		
		if is_instance_valid(self):
			can_play_hurt = true
