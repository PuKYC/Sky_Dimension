# 原始网格存储类
class_name VoxelGrid
extends RefCounted

const SIZE := 64
var _grid := PackedByteArray()

func _init(fill=0):
	_grid.resize(SIZE * SIZE * SIZE)
	_grid.fill(fill)

## 坐标转线性索引（行优先存储）
func _get_index(v3:Vector3) -> int:
	return v3.x + v3.y * SIZE + v3.z * SIZE * SIZE

## 设置方块类型（0-255）
func set_block(v3:Vector3, type: int) -> void:
	assert(_is_valid(v3), "坐标超出范围")
	_grid[_get_index(v3)] = type

## 获取方块类型
func get_block(v3:Vector3) -> int:
	if not _is_valid(v3):
		return -1
	return _grid[_get_index(v3)]

## 转换为RLE压缩格式
func to_rle() -> VoxelGridRLE:
	var rle := VoxelGridRLE.new()
	rle.compress(_grid)
	return rle

## 坐标校验
func _is_valid(v3:Vector3) -> bool:
	return (
		v3.x >= 0 && v3.x < SIZE &&
		v3.y >= 0 && v3.y < SIZE &&
		v3.z >= 0 && v3.z < SIZE
	)

## 获取原始数据（测试用）
func get_raw_data() -> PackedByteArray:
	return _grid.duplicate()

## 从RLE恢复
static func from_rle(rle: VoxelGridRLE) -> VoxelGrid:
	var grid := VoxelGrid.new()
	grid._grid = rle.decompress()
	return grid
