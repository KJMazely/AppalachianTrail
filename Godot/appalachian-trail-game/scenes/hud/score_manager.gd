extends Node

const END_AUDIO_FADE_DURATION := 1.5
const END_AUDIO_TARGET_DB := -40.0

var score := 0
signal ScoreChanged(new_score)

var current_health := 0
#var max_health := 0
signal HealthChanged(new_health, new_max_health)

var start_screen_node: CanvasLayer = null
var end_screen_node: CanvasLayer = null
signal endless_requested

var _end_reason: String = ""
var _allow_endless: bool = false
var _faded_audio_players: Array[Dictionary] = []

func _ready():
	# This ensures the score_manager keeps working even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_points(amount: int):
	score += amount
	ScoreChanged.emit(score)


func set_health(new_health: int, new_max: int):
	current_health = new_health
	#max_health = new_max
	HealthChanged.emit(current_health)

func show_start_screen() -> void:
	if start_screen_node != null or end_screen_node != null:
		return

	start_screen_node = _create_overlay_layer()

	var bg := _create_overlay_background()
	start_screen_node.add_child(bg)

	var label := _create_overlay_label("APPALACHIAN TRAIL\n\nPress Any Key to Start")
	start_screen_node.add_child(label)

	_animate_overlay(bg, label)
	get_tree().paused = true

func end_game(reason: String = "lose", allow_endless: bool = false) -> void:
	# Prevents creating multiple end screens if called twice
	if end_screen_node != null:
		return

	_clear_start_screen()
	_fade_active_audio()
	_end_reason = reason
	_allow_endless = allow_endless and reason == "win"
	
	# 1. Create the overlay layer
	end_screen_node = _create_overlay_layer()

	# 2. Create the Background
	var bg := _create_overlay_background()
	end_screen_node.add_child(bg)

	# 3. Create the Text
	var header_text := "YOU WIN!" if _end_reason == "win" else "THE END"
	var prompt_text := "Press 'R' to Restart"
	if _allow_endless:
		prompt_text += "\nPress 'E' for Endless Mode"
	var label := _create_overlay_label("%s\nFinal Score: %s\n\n%s" % [header_text, str(score), prompt_text])
	end_screen_node.add_child(label)

	# 4. Animation
	_animate_overlay(bg, label)
	
	# 5. Pause the game
	get_tree().paused = true

func _input(event):
	if start_screen_node != null and _is_start_input(event):
		_clear_start_screen()
		return

	# Check if the end screen is currently visible
	if end_screen_node != null:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_R):
			restart_game()
			return

		if _allow_endless:
			if event.is_action_pressed("endless_mode") or (event is InputEventKey and event.keycode == KEY_E):
				start_endless_mode()
				return

func start_endless_mode() -> void:
	if end_screen_node == null:
		return

	_restore_faded_audio()
	get_tree().paused = false

	if end_screen_node:
		end_screen_node.queue_free()
		end_screen_node = null

	endless_requested.emit()

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

func _create_overlay_layer() -> CanvasLayer:
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	return overlay

func _create_overlay_background() -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return bg

func _create_overlay_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate.a = 0
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 60)
	return label

func _animate_overlay(bg: ColorRect, label: Label) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bg, "color", Color(0, 0, 0, 0.9), 1.0)
	tween.tween_property(label, "modulate:a", 1.0, 1.0)

func _is_start_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	return false

func _clear_start_screen() -> void:
	get_tree().paused = false

	if start_screen_node:
		start_screen_node.queue_free()
		start_screen_node = null

func _fade_active_audio() -> void:
	_faded_audio_players.clear()
	_collect_playing_audio(get_tree().root)

	for entry in _faded_audio_players:
		var audio_player: Node = entry["player"]
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(audio_player, "volume_db", END_AUDIO_TARGET_DB, END_AUDIO_FADE_DURATION)

func _restore_faded_audio() -> void:
	for entry in _faded_audio_players:
		var audio_player: Node = entry["player"]
		if not is_instance_valid(audio_player):
			continue
		audio_player.volume_db = entry["volume_db"]

	_faded_audio_players.clear()

func _collect_playing_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		if node.playing:
			_faded_audio_players.append({
				"player": node,
				"volume_db": node.volume_db,
			})

	for child in node.get_children():
		var child_node := child as Node
		if child_node != null:
			_collect_playing_audio(child_node)
