extends TouchControlBase

var center = Vector2.ZERO
var delta = Vector2.ZERO

@export var handle_max_distance = 50.0
@export var deadzone = 0.3

@onready var background = $JoystickBackground
@onready var handle = $JoystickBackground/JoystickHandle


func on_control_started(event: InputEventScreenTouch):
	center = background.global_position + background.size * 0.5 * background.scale
	handle_move(event)
	
func on_control_updated(event: InputEventScreenDrag):
	handle_move(event)
	
func on_control_ended():
	handle.position = background.size * 0.5 * background.scale - handle.size * 0.5 * handle.scale
	Player.set_move_level_input(Vector2.ZERO)
	delta = Vector2.ZERO

func handle_move(event):
	delta = (event.position - center).normalized() * handle_max_distance
	handle.global_position = center + delta - handle.size * 0.5 * handle.scale
	Player.set_move_level_input(delta / handle_max_distance)
