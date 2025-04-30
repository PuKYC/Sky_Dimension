extends RefCounted
class_name Octree

var root: OctreeNode

func _init(world_aabb: AABB, max_objects: int, min_size: float):
	root = OctreeNode.new(world_aabb, max_objects, min_size)

## 插入物体
func insert(obj: Object):
	var obj_aabb = obj.get_aabb()
	root.insert(obj, obj_aabb)

## 查询区域内的物体（自动去重）
func query_aabb(query_aabb: AABB) -> Array:
	var result = []
	root.query(query_aabb, result)
	# 去重处理
	var unique = {}
	for item in result:
		unique[item.get_instance_id()] = item
	return unique.values()

## 清空八叉树
func clear():
	root.clear()
