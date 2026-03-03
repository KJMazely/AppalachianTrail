extends Area2D

@export var stats: Stats
@export var speed := 500.0
@export var damage_shape: Shape2D 

var direction := Vector2.ZERO

func _ready() -> void:
	# 1. Setup Hitbox
	var final_shape = damage_shape
	if not final_shape:
		final_shape = CircleShape2D.new()
		final_shape.radius = 8.0 
	
	var hitbox := Hitbox.new(stats, 5.0, final_shape)
	add_child(hitbox)
	
	
	hitbox.hit_landed.connect(_on_bullet_hit)
	
	#uncomment when wall collision is added
	#body_entered.connect(_on_body_entered)
	
	# Self-destruct after 5 seconds if it hits nothing
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

# This runs when the Hitbox touches a Hurtbox
func _on_bullet_hit() -> void:
	queue_free()

# This runs when the Bullet touches a physical object (Wall, TileMap)
func _on_body_entered(_body: Node2D) -> void:
	queue_free()
