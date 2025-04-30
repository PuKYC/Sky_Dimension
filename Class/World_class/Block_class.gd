extends RefCounted
class_name Blocks_Array

var grid := PackedByteArray()
const SIZE := 64

func _init(fill=0) -> void:
	grid.resize(SIZE * SIZE * SIZE)  # 预分配内存
	grid.fill(fill)  # 初始化为0（空气方块）

# 三维坐标转线性索引
func get_index(x: int, y: int, z: int) -> int:
	return x + y * SIZE + z * SIZE * SIZE

# 设置方块类型
func set_block(x: int, y: int, z: int, type: int):
	grid[get_index(x, y, z)] = type

# 获取方块类型
func get_block(x: int, y: int, z: int) -> int:
	return grid[get_index(x, y, z)]
	
