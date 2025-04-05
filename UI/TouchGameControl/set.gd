extends TouchControlBase

@onready var world = get_tree().get_first_node_in_group("World")

func on_control_started(_event: InputEventScreenTouch):
	pass
	
func on_control_ended():
	world.generate_world()
