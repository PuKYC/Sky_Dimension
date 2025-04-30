extends RefCounted
class_name OctreeNode

var aabb: AABB
var children: Array = []
var objects: Array = []
var max_objects: int
var min_size: float

func _init(p_aabb: AABB, p_max_objects: int, p_min_size: float):
	aabb = p_aabb
	max_objects = p_max_objects
	min_size = p_min_size

## 插入物体及其AABB
func insert(obj: Object, obj_aabb: AABB):
	if not aabb.intersects(obj_aabb):
		return
	
	if children.size() > 0:
		for child in children:
			if child.aabb.intersects(obj_aabb):
				child.insert(obj, obj_aabb)
	else:
		objects.append(obj)
		if objects.size() > max_objects and can_split():
			split()

## 检查是否可以分割
func can_split() -> bool:
	return aabb.size.x > min_size and aabb.size.y > min_size and aabb.size.z > min_size

## 分割节点为八个子节点
func split():
	var half = aabb.size * 0.5
	var child_size = aabb.size / 2
	for x in 2:
		for y in 2:
			for z in 2:
				var origin = Vector3(
					aabb.position.x + x * half.x,
					aabb.position.y + y * half.y,
					aabb.position.z + z * half.z
				)
				var child_aabb = AABB(origin, child_size)
				var child = OctreeNode.new(child_aabb, max_objects, min_size)
				children.append(child)
	# 重新分配物体到子节点
	var temp_objects = objects.duplicate()
	objects.clear()
	for obj in temp_objects:
		var obj_aabb = obj.get_aabb()
		for child in children:
			if child.aabb.intersects(obj_aabb):
				child.insert(obj, obj_aabb)

## 查询与给定AABB相交的物体
func query(query_aabb: AABB, result: Array):
	if not aabb.intersects(query_aabb):
		return
	for obj in objects:
		result.append(obj)
	for child in children:
		child.query(query_aabb, result)

## 清空节点及其子节点
func clear():
	objects.clear()
	for child in children:
		child.clear()
	children.clear()
