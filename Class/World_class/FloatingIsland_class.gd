## 空岛数据结构
extends RefCounted
class_name FloatingIsland

enum IslandState {UNOBSERVED, OBSERVED}

var block_types:Block_Types

var _state: IslandState = IslandState.UNOBSERVED
var floatingisland_AABB: AABB

var _block_Grid: GridPartition
var _block_Grid_mash:Dictionary

func _init(new_floatingisland_AABB: AABB, block_type: Block_Types):
	_block_Grid = GridPartition.new(Vector3.ONE * 32)
	floatingisland_AABB = new_floatingisland_AABB
	block_types = block_type

## 把AABB盒从全局转换到该坐标系
func aabb_global_to_local(aabb_detect: AABB) -> AABB:
	aabb_detect.position = aabb_detect.position - floatingisland_AABB.position
	return aabb_detect

## 更新空岛AABB盒
func update_floatingisland_aabb():
	if _state == IslandState.UNOBSERVED:
		return

## 生成空岛
func generate():
	if _state == IslandState.OBSERVED:
		return
	
	for cell_posi in _block_Grid._get_cells(aabb_global_to_local(floatingisland_AABB)):
		_block_Grid.cells[cell_posi] = [VoxelGrid.new(1)]

	_state = IslandState.OBSERVED
	

func get_voxelgrid(cell:Vector3) -> VoxelGrid:
	for element in _block_Grid.get_cell(cell):
		if element is VoxelGrid:
			return element
	return null

# 生成区块面实例
func generate_mesh(cell: Vector3):
	var voxelgrid = get_voxelgrid(cell)
	if voxelgrid == null:
		return
	
	var cell_tool = VoxelGridMeshTool.new(block_types)
	# 执行面剔除，只记录需要渲染的面
	
	var cells: Array[VoxelGrid]
	for index in cell_tool.FACE_ID:
		cells.append(get_voxelgrid(cell+index))
		
	_block_Grid_mash[cell] = cell_tool.generate_voxelgrid_mesh(voxelgrid, cells)

# 根据AABB获取区块
func get_cells_deta(aabb:AABB) -> Dictionary:
	var mashs: Dictionary
	for mash in _block_Grid._get_cells(aabb_global_to_local(aabb)):
		if _block_Grid_mash.has(mash):
			mashs[mash] = _block_Grid_mash[mash]
	return mashs
	
