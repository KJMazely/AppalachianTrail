class_name Hurtbox extends Area2D

@onready var owner_stats: Stats = owner.get("stats")

func _ready() -> void:
	if not owner_stats:
		print("!!! ERROR: Hurtbox on ", owner.name, " cannot find stats on owner.")
		return

	monitoring = false   # Hurtboxes don't look for things
	monitorable = true   # Hurtboxes CAN be found by hitboxes
	
	# Clear all layers
	collision_layer = 0
	collision_mask = 0
	
	# Set Layer based on faction
	if owner_stats.faction == Stats.Faction.PLAYER:
		set_collision_layer_value(1, true) # Player is on Layer 1
	else:
		set_collision_layer_value(2, true) # Enemy is on Layer 2
	
	print("Hurtbox Ready for: ", owner.name, " on Layer: ", collision_layer)

func receive_hit(damage: int, hitter_position: Vector2) -> void:
	if owner_stats:
		owner_stats.take_damage(damage)
		
	# Tell the enemy script to handle the visual/physical reaction
	if owner.has_method("handle_hit"):
		owner.handle_hit(hitter_position)
