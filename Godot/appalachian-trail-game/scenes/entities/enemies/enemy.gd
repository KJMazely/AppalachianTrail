extends CharacterBody2D

@export_category("Stats")
@export var hitpoints:int = 180

var player_position
var target_position
@onready var player = $"../Player"
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready() -> void:
	animation_tree.set_active(true)

func  take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	if hitpoints <= 0:
		death()


func death() -> void:
	queue_free()
	
func _physics_process(delta):
	player_position = player.position
	target_position = (player_position - position).normalized()
	
	if position.distance_to(player_position) > 0:
		#position.move_toward(target_position,100*delta)
		var direction = target_position
		velocity = direction * 150
		move_and_slide()
