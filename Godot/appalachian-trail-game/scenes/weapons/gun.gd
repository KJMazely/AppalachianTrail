extends Node2D

enum State { IDLE, ATTACK }

@export var shootSpeed = 20000.0
const BULLET = preload("res://scenes/weapons/bullet.tscn")

var state: State = State.IDLE
var canShoot = true
var facing_direction = 1.0 # 1.0 for Right, -1.0 for Left

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var marker_2d = $Marker2D
@onready var shoot_speed_timer = $shootSpeedTimer
@onready var muzzle_flash = $MuzzleFlash

func _ready():
	shoot_speed_timer.wait_time = 1.0 / shootSpeed
	animation_tree.set_active(true)

func _process(_delta):
	update_gun_rotation()
	
	if Input.is_action_just_pressed("shoot"): # Ensure you have a "shoot" action in Input Map
		shoot()

func update_gun_rotation():
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - global_position).normalized()
	
	# CHECK: Is the mouse in front of the player?
	# If facing_direction is 1 (Right) and mouse is Right (dir.x > 0), result is > 0
	# If facing_direction is -1 (Left) and mouse is Left (dir.x < 0), result is > 0
	var is_mouse_in_front = (dir_to_mouse.x * facing_direction) >= 0
	
	if is_mouse_in_front:
		# Point the gun exactly at the mouse
		rotation = dir_to_mouse.angle()
		
		# If we are facing left, the gun is technically upside down due to rotation
		# We flip it on the Y axis so it looks correct
		scale.y = facing_direction 
	else:
		# If mouse is behind, clamp the gun to point straight up or down 
		# based on mouse height, so it doesn't snap awkwardly
		var clamped_angle = -PI/2 if dir_to_mouse.y < 0 else PI/2
		rotation = clamped_angle
		scale.y = facing_direction

func shoot() -> bool:
	if canShoot:
		var mouse_pos = get_global_mouse_position()
		var dir_to_mouse = (mouse_pos - global_position).normalized()
		
		# ONLY SHOOT if the mouse is in the forward 180-degree radius
		if (dir_to_mouse.x * facing_direction) >= 0:
			canShoot = false
			shoot_speed_timer.start()
			
			var bulletNode = BULLET.instantiate()
			
			# Bullet goes exactly towards mouse
			bulletNode.set_direction(dir_to_mouse)
			
			get_tree().root.add_child(bulletNode)
			bulletNode.global_position = marker_2d.global_position
			
			state = State.ATTACK
			update_animation()
			
			return true # NEW: Tells the player "Yes, a bullet fired!"

	return false # NEW: Tells the player "No, it is on cooldown or aiming backwards."

# This is called by your Player script when they move Left or Right
func setup_direction(direction: Vector2):
	if direction.x > 0:
		facing_direction = 1.0
		scale.x = 1
		$MuzzleFlash.flip_v = false
	elif direction.x < 0:
		facing_direction = -1.0
		scale.x = -1
		$MuzzleFlash.flip_v = true

func update_animation():
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.ATTACK:
			animation_playback.travel("attack")
			
func _on_shoot_speed_timer_timeout() -> void:
	canShoot = true
	state = State.IDLE
	update_animation()
