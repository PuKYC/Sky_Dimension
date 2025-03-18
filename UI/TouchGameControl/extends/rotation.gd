extends "res://UI/TouchGameControl/TouchControlBase.gd"

@export var rotation_sensitivity := 0.002
@export var vertical_clamp := Vector2(deg_to_rad(-80), deg_to_rad(80))

var camera_start_rotation = Vector3.ZERO
var touch_start_position = Vector2.ZERO
var position_delta = Vector2.ZERO

@onready var camera = get_tree().get_first_node_in_group("camera")
@onready var UP = $UP
@onready var DOWN = $DOWN

func on_control_started(_event: InputEventScreenTouch):
	camera_start_rotation = camera.rotation
	touch_start_position = _event.position

func on_control_updated(event: InputEventScreenDrag):
	
	position_delta = event.position - touch_start_position
	Player.set_see_rotation(Vector3(
		clampf(camera_start_rotation.x + position_delta.y * rotation_sensitivity, 
			vertical_clamp.x, vertical_clamp.y),
		camera_start_rotation.y + position_delta.x * rotation_sensitivity,
		0
	))

func on_control_ended():
	camera_start_rotation = Vector3.ZERO
	touch_start_position = Vector3.ZERO
	
func is_point_in_control_area(_position: Vector2) -> bool:
	return control_point_in_area(self, _position) and (not control_point_in_area(UP, _position)) and (not control_point_in_area(DOWN, _position)) 
