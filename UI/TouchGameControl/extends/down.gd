extends TouchControlBase

func on_control_started(_event: InputEventScreenTouch):
	Player.set_verticale_down_input(1.0)
	
func on_control_ended():
	Player.set_verticale_down_input(0.0)
