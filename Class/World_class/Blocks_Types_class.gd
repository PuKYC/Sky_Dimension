## 方块种类的集合
## 
## 存放如何渲染
## 以及如何交互
extends Resource
class_name Block_Types

## 存放所有的方块信息
## 
## 说明
## name为方块名称
## block_material存储Texture2DArray中的索引
## transparency为0到100 越大越透明
var block_ID: Dictionary
var block_name: PackedStringArray
var block_material: Array[PackedByteArray]

var img_array: Array

# 修改后的辅助函数（直接操作成员变量）
func _find_and_add_block_name(v: String) -> int:
	var index = block_name.find(v)
	if index == -1:
		block_name.append(v)
		index = block_name.size() - 1
	return index

func _find_and_add_block_material(v: Image) -> int:
	var index = img_array.find(v)
	if index == -1:
		img_array.append(v)
		index = img_array.size() - 1
	return index

func add_block(ID: int, name: String, size: Vector3, materials: PackedStringArray, transparency: int = 0):
	var block_index: Array
	block_index.resize(4)
	block_index[0] = _find_and_add_block_name(name)

	var block_texture2d_array: PackedByteArray
	for material in materials:
		var texture2d = load(material)
		block_texture2d_array.append(_find_and_add_block_material(texture2d.get_image()))
	block_index[1] = block_texture2d_array
	block_index[2] = clamp(0, 100, transparency)
		
	block_ID[ID] = block_index

func get_block_name(id: int) -> String:
	return block_name[block_ID[id][0]]

func get_block_texture2d_id(id: int, normal:Vector3) -> int:
	var ids = block_ID[id][1]
	match ids.size:
		1:
			return ids[0]
		
		3:
			match normal:
				Vector3.UP:
					return ids[0]
				Vector3.DOWN:
					return ids[2]
					
			return ids[1]
		
		6:
			match normal:
				Vector3.FORWARD:
					return ids[0]
				Vector3.BACK:
					return ids[1]
				Vector3.LEFT:
					return ids[2]
				Vector3.RIGHT:
					return ids[3]
				Vector3.UP:
					return ids[4]
				Vector3.DOWN:
					return ids[5]
					
	return 0
	
func get_block_transparency(id: int) -> int:
	return block_ID[id][2]
	
