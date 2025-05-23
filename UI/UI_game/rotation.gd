extends TouchControlBase

@export var rotation_sensitivity := 0.002
@export var vertical_clamp := Vector2(deg_to_rad(-90), deg_to_rad(90))

var camera_start_rotation = Vector3.ZERO
var touch_start_position = Vector2.ZERO
var position_delta = Vector2.ZERO

func on_control_started(_event: InputEventScreenTouch):
	camera_start_rotation = root_connect.get_camera_rotation()
	touch_start_position = _event.position

func on_control_updated(event: InputEventScreenDrag):
	
	position_delta = event.position - touch_start_position
	root_connect.set_see_rotation(Vector3(
		clampf(camera_start_rotation.x + position_delta.y * rotation_sensitivity, 
				vertical_clamp.x, vertical_clamp.y),
		camera_start_rotation.y + position_delta.x * rotation_sensitivity,
		0
	))

func on_control_ended():
	camera_start_rotation = Vector3.ZERO
	touch_start_position = Vector3.ZERO
		


func is_point_in_control_area(pos: Vector2) -> bool:
	return control_point_in_area(self, pos) and is_point_in_node(pos)
	
func is_point_in_node(pos) -> bool:
	for root_child in get_children():
		
		if control_point_in_area(root_child, pos):
			return false
		
		for child in root_child.get_children():
			if control_point_in_area(child, pos):
				return false
		
	return true


func _on_top_pressed() -> void:
	root_connect.set_verticale_up_input(1)


func _on_down_pressed() -> void:
	root_connect.set_verticale_down_input(1)


func _on_top_released() -> void:
	root_connect.set_verticale_up_input(0)
	


func _on_down_released() -> void:
	root_connect.set_verticale_down_input(0)
