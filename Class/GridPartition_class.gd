## 网格分区的godot实现
extends Node3D
class_name GridPartition

## 分区大小
var cell_size: Vector3

var cells: Dictionary    # { Vector3: [object...] }
var object_map: Dictionary    # { object: PackedVector3Array }

func _init(gridpartition_cell_size: Vector3):
	cell_size = gridpartition_cell_size
	cells = {}
	object_map = {}

## 插入对象到覆盖其AABB的所有单元格
func insert(object, aabb: AABB) -> void:
	# 如果已存在则先移除旧数据
	if object_map.has(object):
		remove(object)
		
	# 计算覆盖的单元格坐标
	var cell_coords = _get_cells(aabb)
	
	# 将对象添加到所有覆盖的单元格
	for cell_coord in cell_coords:
		if not cells.has(cell_coord):
			cells[cell_coord] = []
		cells[cell_coord].append(object)
	
	# 记录对象关联的单元格和AABB
	object_map[object] = cell_coords

## 移除对象及其所有单元格关联
func remove(object) -> void:
	if not object_map.has(object):
		return
	
	# 获取对象关联的所有单元格
	var cell_coords: PackedVector3Array = object_map[object]
	
	# 从每个单元格中移除对象引用
	for cell_coord in cell_coords:
		if cells.has(cell_coord):
			cells[cell_coord].erase(object)
	
	# 移除对象记录
	object_map.erase(object)

## 更新对象AABB并重新定位单元格
func update(object, new_aabb: AABB) -> void:
	if not object_map.has(object):
		return
	
	var old_cell_coords: PackedVector3Array = object_map[object]
	var new_cell_coords = _get_cells(new_aabb)
	
	# 如果单元格和AABB都未变化则直接返回
	if new_cell_coords == old_cell_coords:
		return
	
	# 如果单元格范围变化则重新插入
	if new_cell_coords != old_cell_coords:
		remove(object)
		insert(object, new_aabb)

## 查询与指定AABB相交的所有对象
func query(aabb: AABB) -> Array:
	var result = []
	var seen = {}
	
	# 获取查询范围覆盖的单元格
	var query_cells = _get_cells(aabb)
	
	# 收集所有单元格中的唯一对象
	for cell_coord in query_cells:
		if cells.has(cell_coord):
			for obj in cells[cell_coord]:
				if not seen.get(obj, false):
					seen[obj] = true
					result.append(obj)
					
	return result

## 辅助方法：计算AABB覆盖的单元格坐标
## 注意:PackedVector3Array不能存储Vector3i
func _get_cells(aabb: AABB) -> PackedVector3Array:
	var start = floor(aabb.position/cell_size)
	var end = floor(aabb.end/cell_size)
	
	var coords = PackedVector3Array()
	
	## 遍历三维网格范围生成所有单元格坐标
	for x in range(start.x, end.x + 1):
		for y in range(start.y, end.y + 1):
			for z in range(start.z, end.z + 1):
				coords.append(Vector3(x, y, z))
	
	return coords

func get_cell(cell: Vector3) -> Array:
	if cells.has(cell):
		return cells[cell]
	return []

## 是否有cell
func is_get_cell(cell:Vector3):
	return cells.has(cell)

func has_point(point:Vector3) -> Vector3:
	return floor(point/cell_size)

## 获取cell的坐标
func get_cell_position(cell: Vector3):
	return cell * cell_size
