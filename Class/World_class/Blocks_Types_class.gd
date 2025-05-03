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
## size指使用大小方块 大方块为0 小方块为1
## block_material存储Texture2DArray中的索引
var block_ID: Dictionary
var block_name: PackedStringArray
var block_size: PackedVector3Array
var block_material: Array[PackedByteArray]

var img_array: Array

# 修改后的辅助函数（直接操作成员变量）
func _find_and_add_block_name(v: String) -> int:
        var index = block_name.find(v)
        if index == -1:
                block_name.append(v)
                index = block_name.size() - 1
        return index

func _find_and_add_block_size(v: Vector3) -> int:
        var index = block_size.find(v)
        if index == -1:
                block_size.append(v)
                index = block_size.size() - 1
        return index

func _find_and_add_block_material(v: Image) -> int:
        var index = img_array.find(v)
        if index == -1:
                img_array.append(v)
                index = img_array.size() - 1
        return index

func add_block(ID:int, name:String, size:Vector3, materials: PackedStringArray):
        var block_index:Array
        block_index.resize(3)
        block_index[0] = _find_and_add_block_name(name)
        block_index[1] = _find_and_add_block_size(size)

        var block_texture2d_array:PackedByteArray
        for material in materials:
                var texture2d = load(material)
                block_texture2d_array.append(_find_and_add_block_material(texture2d.get_image()))
        block_index[2] = block_texture2d_array

        block_ID[ID] = block_index
