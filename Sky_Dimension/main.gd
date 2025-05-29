extends Node3D

@onready var world = $World
@onready var player = $Player
@onready var camera = $Player/camera_position

func set_move_level_input(input: Vector2):
	player.direction_level = Vector2(input.x, input.y)

func set_see_rotation(set_see_rotation_input: Vector3):
	camera.rotation = set_see_rotation_input

func set_verticale_up_input(input: float):
	player.direction_verticale_up = input
	
func set_verticale_down_input(input: float):
	player.direction_verticale_down = input

func get_player_position() -> Vector3:
	return player.position

func get_camera_rotation() -> Vector3:
	return camera.rotation

func _process(delta):
	var pos = player.position
	# 显示保留1位小数的坐标（按需调整格式）
	$UI/Label.text = "Position: (%.1f, %.1f, %.1f)" % [pos.x, pos.y, pos.z]
