extends Area2D

@export var stats: Stats
@export var speed: float = 340.0
@export var lifetime: float = 5.0
@export var damage_shape: Shape2D
@export var projectile_attack: int = -1
@export var projectile_size_scale: float = 1.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# TODO: Replace ProjectileBody Polygon2D with your boulder/pebble sprite setup.
	# Keep the node name "ProjectileBody" or update the lookup below.
	var final_shape := damage_shape
	if not final_shape:
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		final_shape = circle

	if final_shape is CircleShape2D:
		var circle_shape := (final_shape as CircleShape2D).duplicate()
		circle_shape.radius *= projectile_size_scale
		final_shape = circle_shape

	var attack_stats := stats
	if stats and projectile_attack >= 0:
		attack_stats = stats.duplicate()
		attack_stats.current_attack = projectile_attack

	var hitbox := Hitbox.new(attack_stats, lifetime, final_shape)
	add_child(hitbox)
	hitbox.hit_landed.connect(_on_hit_landed)

	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	var visual := get_node_or_null("ProjectileBody")
	if visual and visual is Node2D:
		(visual as Node2D).scale = Vector2.ONE * projectile_size_scale

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_hit_landed() -> void:
	queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
