# 原始网格存储类
class_name VoxelGrid
extends RefCounted

const SIZE := 64
var _grid := PackedByteArray()

func _init(fill=0):
        _grid.resize(SIZE * SIZE * SIZE)
        _grid.fill(fill)

## 坐标转线性索引（行优先存储）
func _get_index(x: int, y: int, z: int) -> int:
        return x + y * SIZE + z * SIZE * SIZE

## 设置方块类型（0-255）
func set_block(x: int, y: int, z: int, type: int) -> void:
        assert(_is_valid(x, y, z), "坐标超出范围")
        _grid[_get_index(x, y, z)] = type

## 获取方块类型
func get_block(x: int, y: int, z: int) -> int:
        assert(_is_valid(x, y, z), "坐标超出范围")
        return _grid[_get_index(x, y, z)]

## 转换为RLE压缩格式
func to_rle() -> VoxelGridRLE:
        var rle := VoxelGridRLE.new()
        rle.compress(_grid)
        return rle

## 坐标校验
func _is_valid(x: int, y: int, z: int) -> bool:
        return (
                x >= 0 && x < SIZE &&
                y >= 0 && y < SIZE &&
                z >= 0 && z < SIZE
        )

## 获取原始数据（测试用）
func get_raw_data() -> PackedByteArray:
        return _grid.duplicate()

## 从RLE恢复
static func from_rle(rle: VoxelGridRLE) -> VoxelGrid:
        var grid := VoxelGrid.new()
        grid._grid = rle.decompress()
        return grid