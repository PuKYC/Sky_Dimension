extends Node3D

@onready var array_world = $array_world

#世界
var world = []

#方块列表
var blocks = {
	0:["泥土", "res://World/block_png/coarse_dirt.png"],
	1:["草方块", "res://World/block_png/green_concrete.png"],
	2:["石头", "res://World/block_png/leaves_birch_opaque.png"]
}


#判断点是否在圆内
func is_point_in_circle(point: Vector2, circle_center: Vector2, radius: int) -> bool:
	return point.distance_squared_to(circle_center) <= radius * radius

#生成平面圆形
func generate_circle(circle_center: Vector3, radius: int) -> Array:
	var world_list = []
	var id_list:PackedInt32Array = []
	var position_list:PackedVector3Array = []
	
	for m in range(-radius, radius+1):
		for n in range(-radius, radius+1):
			if is_point_in_circle(Vector2(m, n), Vector2(circle_center.x, circle_center.y), radius):
				position_list.append(Vector3(m, 0, n))
				id_list.append(0)
	
	world_list.append(position_list)
	world_list.append(id_list)
	
	return world_list

#生成世界
func generate_world():
	var time = Time.get_ticks_usec()
	world = generate_circle(Vector3(0, 0, 0), 300)
	add_block(Vector3(0, 1, 0), 1)
	add_block(Vector3(0, 2, 0), 2)
	array_world.set_world(world)
	print("生成世界耗时：", (Time.get_ticks_usec()-time)/1000.0/1000.0)
	
func add_block(posi:Vector3, id:int):
	world[0].append(posi)
	world[1].append(id)

func _ready() -> void:
	array_world.blocks = blocks
