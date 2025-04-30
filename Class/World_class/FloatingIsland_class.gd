## 空岛数据结构
extends GridPartition
class_name FloatingIsland

var floatingisland_AABB: AABB

## 在空岛生成阶段的数据
var generation_date: Dictionary = {}

func _init(new_floatingisland_AABB: AABB):
	floatingisland_AABB = new_floatingisland_AABB
	cell_size = Vector3i.ONE * 32
	cells = {}
	object_map = {}
	generation_date["generation_floatingisland_cells"] = _get_cells(new_floatingisland_AABB)

## 返回AABB与空岛区块的交集 ｛ V3(区块的世界坐标)：(区块方块) ｝
func return_partial_islands(aabb_detect: AABB) -> Dictionary:
	var block_cells = {}
	for cell in _get_cells(aabb_global_to_local(aabb_detect)):
		var cell_v3i = Vector3i(cell)
		if not is_get_cell(cell_v3i):
			if not generate_cell(cell_v3i):
				continue
		block_cells[cell_local_to_global(cell)] = cells[cell_v3i]
		
	return block_cells

## 把cell从局部坐标系转换到全局坐标系
func cell_local_to_global(cell:Vector3i):
	return Vector3(cell) + floatingisland_AABB.position

## 把AABB盒从全局转换到该坐标系
func aabb_global_to_local(aabb_detect: AABB) -> AABB:
	aabb_detect.position = aabb_detect.position - floatingisland_AABB.position
	return aabb_detect

## 返回空岛AABB盒
func return_floatingisland_aabb():
	pass

## 更新空岛AABB盒
func update_floatingisland_aabb():
	pass

## 生成区块
func generate_cell(cell_posi: Vector3) -> bool:
	if not generation_date.has("generation_floatingisland_cells"):
		return false
		
	if cell_posi in generation_date["generation_floatingisland_cells"]:
		var cell_posi_v3i = Vector3i(cell_posi)
		cells[cell_posi_v3i] = Blocks_Array.new(1)
		return true
		
	return false
