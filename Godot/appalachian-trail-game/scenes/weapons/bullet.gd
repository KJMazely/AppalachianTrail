extends Area2D

@export var hitbox_shape: Shape2D
@export var stats: Stats
@export var speed = 500
@export var damage = 1

var direction:Vector2

func _ready() -> void:
	await get_tree().create_timer(10).timeout
	queue_free()

func set_direction(bulletDirection):
	direction = bulletDirection
	rotation_degrees = rad_to_deg(global_position.angle_to_point(global_position+direction))

func _physics_process(delta) -> void:
	global_position += direction * speed * delta
	var hitbox = Hitbox.new(stats, 10, hitbox_shape)
	add_child(hitbox)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.get_damage(damage)
		queue_free()
