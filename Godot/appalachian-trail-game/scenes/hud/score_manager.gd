extends Node

var score := 0

func add_points(amount: int):
	score += amount
	ScoreChanged.emit(score)

signal ScoreChanged(new_score)
