extends CharacterBody3D

@export var move_speed = 5.0  # 移动速度（米/秒）

var direction = Vector3.ZERO
var direction_level = Vector2.ZERO
var direction_verticale_up = 0.0
var direction_verticale_down = 0.0

@onready var camera  = $camera

func _physics_process(delta):
	direction = Vector3(direction_level.x, direction_verticale_up-direction_verticale_down, direction_level.y).normalized()
	velocity = direction.rotated(Vector3.UP, camera.rotation.y) * move_speed * delta * 100
	move_and_slide()
