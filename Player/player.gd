extends CharacterBody3D

@export var move_speed = 5.0  # 移动速度（米/秒）
@onready var direction = Vector3.ZERO
var direction_level = Vector2.ZERO
var direction_verticale_up = 0.0
var direction_verticale_down = 0.0

@onready var camera  = $camera

func _physics_process(delta):
	direction = Vector3(direction_level.x, direction_verticale_up-direction_verticale_down, direction_level.y).normalized()
	velocity = direction.rotated(Vector3.UP, camera.rotation.y) * move_speed * delta * 100
	move_and_slide()

# 外部更新输入（由摇杆调用）
func set_move_level_input(input: Vector2):
	direction_level = Vector2(input.x, input.y)

func set_see_rotation(set_see_rotation_input: Vector3):
	camera.rotation = set_see_rotation_input

func set_verticale_up_input(input: float):
	direction_verticale_up = input
	
func set_verticale_down_input(input: float):
	direction_verticale_down = input
