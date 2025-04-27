## 世界的管理类
extends Node3D
class_name World_manager

@export var blocks_array: Blocks_Array

var floatingisland_gridpartition: GridPartition

func generate_floatingisland():
	floatingisland_gridpartition.insert(FloatingIsland.new(AABB(Vector3.ZERO, Vector3.ONE*1024)), AABB(Vector3.ZERO, Vector3.ONE*1024))

## 从文件加载世界的某个部分的数据
func load_from_file():
	pass

## 保存世界的某个部分到文件
func save_to_file():
	pass

func _init() -> void:
	floatingisland_gridpartition = GridPartition.new(Vector3i.ONE * 4096)
