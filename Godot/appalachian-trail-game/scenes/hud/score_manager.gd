extends Node

var score := 0
signal ScoreChanged(new_score)

var current_health := 0
#var max_health := 0
signal HealthChanged(new_health, new_max_health)

var end_screen_node: CanvasLayer = null

func _ready():
	# This ensures the score_manager keeps working even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_points(amount: int):
	score += amount
	ScoreChanged.emit(score)


func set_health(new_health: int, new_max: int:
	current_health = new_health
	#max_health = new_max
	HealthChanged.emit(current_health)

func end_game():
	# Prevents creating multiple end screens if called twice
	if end_screen_node != null: return 
	
	# 1. Create the overlay layer
	end_screen_node = CanvasLayer.new()
	end_screen_node.layer = 100
	add_child(end_screen_node)

	# 2. Create the Background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_screen_node.add_child(bg)

	# 3. Create the Text
	var label = Label.new()
	label.text = "THE END\nFinal Score: " + str(score) + "\n\nPress 'R' to Restart"
	label.horizontal_alignment = 1 
	label.vertical_alignment = 1
	label.modulate.a = 0
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 60)
	end_screen_node.add_child(label)

	# 4. Animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bg, "color", Color(0, 0, 0, 0.9), 1.0)
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	
	# 5. Pause the game
	get_tree().paused = true

func _input(event):
	# Check if the end screen is currently visible
	if end_screen_node != null:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_R):
			restart_game()

func restart_game():
	# 1. Unpause the game first
	get_tree().paused = false
	
	# 2. Reset the score
	score = 0
	
	# 3. REMOVE the "The End" UI
	if end_screen_node:
		end_screen_node.queue_free()
		end_screen_node = null
	
	# 4. Reload the scene
	get_tree().reload_current_scene()
