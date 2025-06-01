## 空岛数据结构
extends GridPartition
class_name FloatingIsland

enum IslandState {UNOBSERVED, OBSERVED}

var block_types:Block_Types

var _state: IslandState = IslandState.UNOBSERVED
var floatingisland_AABB: AABB

# 存储网格实例和网格数据
var _list_Grid_mash:Dictionary # 存储MeshInstance3D节点
var _block_Grid_mash:Dictionary # 存储ArrayMesh数据

func _init():
	super._init(Vector3.ONE * 64)
	_list_Grid_mash = {}
	_block_Grid_mash = {}

## 把AABB盒从全局转换到该坐标系
func aabb_global_to_local(aabb_detect: AABB) -> AABB:
	aabb_detect.position = aabb_detect.position - floatingisland_AABB.position
	return aabb_detect

## 生成空岛
func generate():
	if _state == IslandState.OBSERVED:
		return
	
	for cell_posi in _get_cells(aabb_global_to_local(floatingisland_AABB)):
		var vox := VoxelGrid.new()
		vox.fill(1)
		cells[cell_posi] = [vox]
	
	_state = IslandState.OBSERVED

func get_voxelgrid(cell:Vector3) -> VoxelGrid:
	for element in get_cell(cell):
		if element is VoxelGrid:
			return element
	return null

# 生成网格数据
func generate_mesh_data(cell: Vector3) -> ArrayMesh:
	var voxelgrid = get_voxelgrid(cell)
	if voxelgrid == null:
		return null
	
	var cell_tool = VoxelGridMeshTool.new()
	var cells_arr: Array[VoxelGrid] = []
	cells_arr.resize(6)
	
	cells_arr[VoxelGridMeshTool.FRONT] = get_voxelgrid(cell+Vector3.FORWARD)
	cells_arr[VoxelGridMeshTool.BACK] = get_voxelgrid(cell+Vector3.BACK)
	cells_arr[VoxelGridMeshTool.TOP] = get_voxelgrid(cell+Vector3.UP)
	cells_arr[VoxelGridMeshTool.BOTTOM] = get_voxelgrid(cell+Vector3.DOWN)
	cells_arr[VoxelGridMeshTool.RIGHT] = get_voxelgrid(cell+Vector3.RIGHT)
	cells_arr[VoxelGridMeshTool.LEFT] = get_voxelgrid(cell+Vector3.LEFT)
	
	return cell_tool.generate_voxelgrid_mesh(
		voxelgrid, cells_arr, block_types, Vector3.ZERO
	)
