class_name Hitbox extends Area2D

signal hit_landed

var attacker_stats: Stats
var hitbox_lifetime: float
var shape: Shape2D
var hit_log: HitLog

func _init(_attacker_stats: Stats, _hitbox_lifetime: float, _shape: Shape2D, _hitlog: HitLog = null) -> void:
	attacker_stats = _attacker_stats
	hitbox_lifetime = _hitbox_lifetime
	shape = _shape
	hit_log = _hitlog

func _ready() -> void:
	monitoring = true     # Hitboxes look for things
	monitorable = false   # Hitboxes cannot be hit by other hitboxes
	
	area_entered.connect(_on_area_entered)
	
	# Setup Collision Shape
	if shape:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)
	else:
		print("!!! ERROR: Hitbox created with NO SHAPE!")

	# Setup Timer
	if hitbox_lifetime > 0.0:
		get_tree().create_timer(hitbox_lifetime).timeout.connect(queue_free)
	
	# Setup Mask (Looking for the OPPOSITE faction)
	collision_layer = 0
	collision_mask = 0
	
	if attacker_stats.faction == Stats.Faction.PLAYER:
		set_collision_mask_value(2, true) # Player looks for Enemies (Layer 2)
	else:
		set_collision_mask_value(1, true) # Enemy looks for Player (Layer 1)

func _on_area_entered(area: Area2D) -> void:
	print("Hitbox touched: ", area.name)
	if area is Hurtbox:
		var hurtbox_owner = area.owner
		if hit_log:
			if hit_log.has_hit(hurtbox_owner): return
			hit_log.log_hit(hurtbox_owner)
		
		# PASS global_position so the enemy knows which way to fly
		area.receive_hit(attacker_stats.current_attack, global_position)
		hit_landed.emit()
