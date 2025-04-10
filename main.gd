extends Node3D

@onready var world = $World
@onready var player = $Player

func Overload_world():
	world.generate_world()

# 外部更新输入（由摇杆调用）
func set_move_level_input(input: Vector2):
	player.direction_level = Vector2(input.x, input.y)

func set_see_rotation(set_see_rotation_input: Vector3):
	player.camera.rotation = set_see_rotation_input

func set_verticale_up_input(input: float):
	player.direction_verticale_up = input
	
func set_verticale_down_input(input: float):
	player.direction_verticale_down = input

func get_camera_rotation() -> Vector3:
	return player.camera.rotation 
