extends Node2D


@onready var anim = $AnimationPlayer

func _ready():
	anim.play("Death")

func _on_animation_player_animation_finished(anim_name):
	queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
