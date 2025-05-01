# RLE压缩存储类
class_name VoxelGridRLE
extends RefCounted

var compressed_data := []
var _index_map := {}

func compress(grid: PackedByteArray) -> void:
	compressed_data.clear()
	if grid.is_empty():
		return
	
	var current_type = grid[0]
	var count := 1
	
	for i in range(1, grid.size()):
		if grid[i] == current_type:
			count += 1
		else:
			_add_segment(current_type, count)
			current_type = grid[i]
			count = 1
	_add_segment(current_type, count)
	_build_index()

func decompress() -> PackedByteArray:
	var grid := PackedByteArray()
	grid.resize(64 * 64 * 64)
	var ptr := 0
	
	for segment in compressed_data:
		var type = segment[0]
		var length = segment[1]
		# 修复fill参数错误
		for i in range(length):
			if ptr + i < grid.size():
				grid[ptr + i] = type
		ptr += length
	
	return grid

func to_voxel_grid() -> VoxelGrid:
	return VoxelGrid.from_rle(self)

static func from_voxel_grid(grid: VoxelGrid) -> VoxelGridRLE:
	var rle := VoxelGridRLE.new()
	rle.compress(grid.get_raw_data())
	return rle

func get_block(x: int, y: int, z: int) -> int:
	var index = x + y * 64 + z * 4096
	var keys = _index_map.keys()
	keys.sort()  # 修复sort返回值问题
	
	var pos = keys.bsearch(index)
	if pos >= keys.size():
		return 0
	
	var seg_idx = _index_map[keys[pos]]
	var seg = compressed_data[seg_idx]
	return seg[0]

func _add_segment(type: int, length: int) -> void:
	compressed_data.append([type, length])

func _build_index() -> void:
	_index_map.clear()
	var total := 0
	for i in compressed_data.size():
		_index_map[total] = i
		total += compressed_data[i][1]

func validate() -> bool:
	var total := 0
	for seg in compressed_data:
		total += seg[1]
	return total == 64 * 64 * 64
