extends "res://UI/TouchGameControl/TouchControlBase.gd"


func on_control_started(_event: InputEventScreenTouch):
	Player.set_verticale_up_input(1.0)
	
func on_control_ended():
	Player.set_verticale_up_input(0.0)
