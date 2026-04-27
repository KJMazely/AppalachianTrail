extends CanvasLayer

func _ready():
	$ScoreLabel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	$ScoreLabel.anchor_left = 1.0
	$ScoreLabel.anchor_right = 1.0
	$ScoreLabel.offset_left = 0
	$ScoreLabel.offset_right = -10
	var score_manager := get_node_or_null("/root/ScoreManager")
	if score_manager != null:
		score_manager.ScoreChanged.connect(_on_score_changed)
		score_manager.HealthChanged.connect(_on_health_changed)

func _on_score_changed(new_score: int):
	$ScoreLabel.text = "Score: " + str(new_score)
	

func _on_health_changed(new_health: int):
	$HealthLabel.text = "Health: " + str(new_health)
