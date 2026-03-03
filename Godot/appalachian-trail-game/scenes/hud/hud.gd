extends CanvasLayer

func _ready():
	print("HUD ready, connecting signal")
	$ScoreLabel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	$ScoreLabel.anchor_left = 1.0
	$ScoreLabel.anchor_right = 1.0
	$ScoreLabel.offset_left = 0
	$ScoreLabel.offset_right = -10
	ScoreManager.ScoreChanged.connect(_on_score_changed)

func _on_score_changed(new_score: int):
	$ScoreLabel.text = "Score: " + str(new_score)
