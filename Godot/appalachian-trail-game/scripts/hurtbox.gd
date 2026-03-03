class_name Hurtbox extends Area2D

func _ready() -> void:
	monitoring = false
	monitorable = true # Must be true so hitboxes can find it
	
	# Logic to set layers based on owner's faction
	collision_layer = 0
	collision_mask = 0
	
	# Wait one frame to ensure owner stats are ready
	await get_tree().process_frame
	if owner.get("stats"):
		var faction = owner.stats.faction
		if faction == Stats.Faction.PLAYER:
			set_collision_layer_value(1, true) # Player is Layer 1
		else:
			set_collision_layer_value(2, true) # Enemy is Layer 2

func receive_hit(damage: int, hitter_position: Vector2) -> void:
	if owner.get("stats"):
		owner.stats.take_damage(damage)
	
	if owner.has_method("handle_hit"):
		owner.handle_hit(hitter_position)
