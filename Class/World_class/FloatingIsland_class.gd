## 空岛数据结构
extends GridPartition
class_name FloatingIsland

var floatingisland_AABB: AABB

## 在空岛生成阶段的数据
var generation_date: Dictionary

func _init(new_floatingisland_AABB):
	floatingisland_AABB = new_floatingisland_AABB
	cell_size = Vector3i.ONE * 36
	cells = {}
	object_map = {}

## 返回AABB与空岛区块的交集 ｛ V3(区块的世界坐标)：(区块方块) ｝
func reture_partial_islands(aabb_detect: AABB) -> Dictionary:
	var block_cells = {}
	for cell in _get_cells(aabb_global_to_local(aabb_detect)):
		if is_get_cell(cell):
			block_cells[cell_local_to_global(cell)] = cells[cell]
	return block_cells

## 把cell从局部坐标系转换到全局坐标系
func cell_local_to_global(cell:Vector3i):
	return Vector3(cell) + floatingisland_AABB.position

## 把AABB盒从全局转换到该坐标系
func aabb_global_to_local(aabb_detect: AABB) -> AABB:
	aabb_detect.position = aabb_detect.position - floatingisland_AABB.position
	return aabb_detect
	

## 返回空岛AABB盒
func reture_floatingisland_aabb():
	pass

## 更新空岛AABB盒
func update_floatingisland_aabb():
	pass
