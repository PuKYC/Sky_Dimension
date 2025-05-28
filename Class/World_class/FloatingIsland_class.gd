## 空岛数据结构
extends GridPartition
class_name FloatingIsland

enum IslandState {UNOBSERVED, OBSERVED}

var block_types:Block_Types

var _state: IslandState = IslandState.UNOBSERVED
var floatingisland_AABB: AABB

var _l_Grid_mash:Dictionary
var _block_Grid_mash:Dictionary

func _init():
	super._init(Vector3.ONE * 64)

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

func generate_meshs():
	for cell in cells.keys():
		generate_mesh(cell)

# 生成区块面实例
func generate_mesh(cell: Vector3):
	if _block_Grid_mash.has(cell):
		return
	var voxelgrid = get_voxelgrid(cell)
	if voxelgrid == null:
		return
	
	var cell_tool = VoxelGridMeshTool.new()
	# 执行面剔除，只记录需要渲染的面
	
	var cells: Array[VoxelGrid]
	cells.resize(6)
	
	cells[VoxelGridMeshTool.FRONT] = get_voxelgrid(cell+Vector3.FORWARD)
	cells[VoxelGridMeshTool.BACK] = get_voxelgrid(cell+Vector3.BACK)
	cells[VoxelGridMeshTool.TOP] = get_voxelgrid(cell+Vector3.UP)
	cells[VoxelGridMeshTool.BOTTOM] = get_voxelgrid(cell+Vector3.DOWN)
	cells[VoxelGridMeshTool.RIGHT] = get_voxelgrid(cell+Vector3.RIGHT)
	cells[VoxelGridMeshTool.LEFT] = get_voxelgrid(cell+Vector3.LEFT)
	
	_block_Grid_mash[cell] = cell_tool.generate_voxelgrid_mesh(voxelgrid, cells, block_types, get_cell_position(cell))
	
	#print(_block_Grid_mash[cell])
	
# 根据AABB获取区块
func get_cells_deta(aabb:AABB):
	
	for mesh in _get_cells(aabb_global_to_local(aabb)):
		#print(aabb_global_to_local(aabb))
		#print(_get_cells(aabb_global_to_local(aabb)))
		var mesh_node = MeshInstance3D.new()
		
		if _block_Grid_mash.has(mesh):
			#print(1)
			mesh_node.name = "%.1f, %.1f, %.1f" % [mesh.x, mesh.y, mesh.z]
			mesh_node.mesh = _block_Grid_mash[mesh]
			mesh_node.position = floatingisland_AABB.position
			mesh_node.material_override = block_types.get_material()
			if not _l_Grid_mash.has(mesh):
				add_child(mesh_node)
				_l_Grid_mash[mesh] = true
			
	
