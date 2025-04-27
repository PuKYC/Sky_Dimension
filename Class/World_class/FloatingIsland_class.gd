## 空岛数据结构
extends Node3D
class_name FloatingIsland

var floatingisland_AABB: AABB
var floatingisland_block: GridPartition

## 在空岛生成阶段的数据
var generation_date: Dictionary

func _init(new_floatingisland_AABB):
	floatingisland_AABB = new_floatingisland_AABB
	floatingisland_block = GridPartition.new(Vector3.ONE*32)

## 返回AABB与空岛区块的交集
func reture_partial_islands(aabb_detect: AABB) -> Dictionary:
	var cells = {}
	for cell in floatingisland_block._get_cells(aabb_detect):
		cells[cell] = floatingisland_block.cells[cell]
	return cells

## 返回空岛AABB盒
func reture_floatingisland_aabb():
	pass

## 更新空岛AABB盒
func update_floatingisland_aabb():
	pass
