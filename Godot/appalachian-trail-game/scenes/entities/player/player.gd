extends CharacterBody2D

enum State {
	IDLE,
	MOVING,
	ATTACK,
	DEAD
}

@export_category("Stats")
@export var speed: int = 400
@export var attack_speed: float = 0.6

var state: State = State.IDLE
var get_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var muzzle_flash: Sprite2D = $MuzzleFlash
@onready var gun = $Gun



func _ready() -> void:
	animation_tree.set_active(true)
	muzzle_flash.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()

func _physics_process(delta):
	
	if Input.is_action_pressed("attack"):
		gun.shoot()
	
	movement_loop()
	#look_at(get_global_mouse_position())
	
	

func movement_loop() -> void:
	muzzle_flash.visible = false
	get_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	get_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	var motion: Vector2 = get_direction.normalized() * speed
	set_velocity(motion)
	
	if get_direction != Vector2.ZERO:
		gun.setup_direction(get_direction)
	
	move_and_slide()
	
	#sprite flip
	if state == State.IDLE or State.MOVING:
		if get_direction.x < -0.01:
			$Sprite2D.flip_h = true
		elif get_direction.x > 0.01:
			$Sprite2D.flip_h = false

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
	muzzle_flash.visible = true
	state = State.ATTACK
	update_animation()
	
	#Return to idle state after attack anim is done
	state = State.IDLE
