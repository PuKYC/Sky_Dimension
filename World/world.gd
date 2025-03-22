extends Node3D

@onready var array_world = $array_world

var world = []

#判断点是否在圆内
func is_point_in_circle(point: Vector2, circle_center: Vector2, radius: int) -> bool:
	return point.distance_squared_to(circle_center) <= radius * radius


func generate_circle(circle_center: Vector3, radius: int) -> Array:
	var world_list = []
	var id_list = []
	var position_list = []
	
	for m in range(-radius, radius+1):
		for n in range(-radius, radius+1):
			if is_point_in_circle(Vector2(m, n), Vector2(circle_center.x, circle_center.y), radius):
				position_list.append(Vector3(m, 0, n))
				id_list.append(1)
	
	world_list.append(position_list)
	world_list.append(id_list)
	
	return world_list


func generate_world() -> Array:
	return generate_circle(Vector3(0, 0, 0), 3)


func _ready() -> void:
	world = generate_world()
	array_world.set_world(world)
	
