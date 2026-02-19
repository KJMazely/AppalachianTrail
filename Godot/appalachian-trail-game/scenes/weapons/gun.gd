extends Node2D

enum State {
	IDLE,
	ATTACK
}

@export var shootSpeed = 1.0

const BULLET = preload("res://scenes/weapons/bullet.tscn")
var state: State = State.IDLE

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var muzzle_flash: Sprite2D = $MuzzleFlash
@onready var marker_2d = $Marker2D
@onready var shoot_speed_timer = $shootSpeedTimer

var canShoot = true
var bulletDirection = Vector2(1,0)

func _ready():
	shoot_speed_timer.wait_time = 1.0 / shootSpeed
	animation_tree.set_active(true)

func shoot():
	if canShoot:
		canShoot = false
		shoot_speed_timer.start()
		
		var bulletNode = BULLET.instantiate()
		
		bulletNode.set_direction(bulletDirection)
		get_tree().root.add_child(bulletNode)
		bulletNode.global_position = marker_2d.global_position
		state = State.ATTACK
		update_animation()


func update_animation():
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.ATTACK:
			animation_playback.travel("attack")

func _on_shoot_speed_timer_timeout() -> void:
	canShoot = true

func setup_direction(direction):
	bulletDirection = direction
	
	if direction.x > 0:
		scale.x = 1
		rotation_degrees = 0
		#$MuzzleFlash.flip_v = false
		#$MuzzleFlash.position.x = -4
	elif direction.x < 0:
		scale.x = -1
		rotation_degrees = 0
		#$MuzzleFlash.flip_v = true
		#$MuzzleFlash.position.x = 4
	elif direction.y < 0:
		scale.x = 1
		rotation_degrees = -90
	elif direction.y > 0:
		scale.x = 1
		rotation_degrees = 90
