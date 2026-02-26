extends Area2D
class_name HurtBox

signal hurt()
signal died()

@export var healthPoints:= 3

func get_damage(value: int):
	healthPoints -= value
	
	hurt.emit()
	
	if healthPoints <= 0:
		died.emit()
