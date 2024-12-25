class_name UI extends Node2D

signal toggled_soldier_mode

signal was_cancelled
signal was_confirmed



func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_action_pressed("add_soldier"):
			toggled_soldier_mode.emit()
		if event.is_action_pressed("cancel"):
			was_cancelled.emit() 
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_action_pressed("cancel"):
				was_cancelled.emit()
