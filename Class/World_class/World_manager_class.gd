## 空岛数据管理类
extends GridPartition
class_name World_manager

func _init() -> void:
	cell_size = Vector3i.ONE * 4096
	cells = {}
	object_map = {}

## 生成单个空岛
func generate_floatingisland(floatingisland_position: Vector3, size: Vector3):
	var floatingisland_aabb = AABB(floatingisland_position, size)
	insert(FloatingIsland.new(floatingisland_aabb), floatingisland_aabb)

## 查询所有空岛的与AABB相交的区块
func query_floatingisland_cell(aabb: AABB) -> Dictionary:
	var floatingisland_array = query(aabb)
	var floatingisland_cell := {}
	for floatingisland in floatingisland_array:
		floatingisland_cell.merge(floatingisland.return_partial_islands(aabb))
	
	return floatingisland_cell

## 从文件加载世界的某个部分的数据
func load_from_file():
	pass

## 保存世界的某个部分到文件
func save_to_file():
	pass
