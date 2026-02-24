extends CanvasLayer

func _ready() -> void:
	# 1. Set the starting values immediately
	%Label.text = "Score: " + str(ScoreManager.score)
	
	# 2. Tell the HUD to listen for changes from the Autoload
	ScoreManager.score_changed.connect(update_score)

# 3. The update functions
func update_score(new_score: int) -> void:
	%Label.text = "Score: " + str(new_score)
