## 空岛数据结构
extends GridPartition
class_name FloatingIsland

enum IslandState {UNOBSERVED, OBSERVED}

var block_types:Block_Types

var _state: IslandState = IslandState.UNOBSERVED
var floatingisland_AABB: AABB

var _list_Grid_mesh:Dictionary
var _block_Grid_mesh:Dictionary

# 线程池和任务管理
var _mesh_thread_pool := []
const MAX_THREADS := 4
var _pending_mesh_tasks := {}
var _mesh_mutex := Mutex.new()
var _mesh_semaphore := Semaphore.new()

# 新增：实例创建队列和帧率控制
var _mesh_creation_queue := []  # 存储待创建的网格实例
var _mesh_queue_mutex := Mutex.new()
const MAX_INSTANCES_PER_FRAME = 2  # 每帧最多创建的实例数量
var _pause_mesh_creation = false   # 当队列过长时暂停创建

func _init():
	super._init(Vector3.ONE * 64)
	# 初始化线程池
	for i in range(MAX_THREADS):
		var thread = Thread.new()
		_mesh_thread_pool.append(thread)

func _exit_tree():
	# 安全退出所有线程
	for thread in _mesh_thread_pool:
		if thread.is_started():
			thread.wait_to_finish()

func _process(_delta):
	# 每帧处理有限数量的网格实例
	_process_mesh_creation_queue()

## 处理网格创建队列（每帧调用）
func _process_mesh_creation_queue():
	if _pause_mesh_creation:
		return
		
	_mesh_queue_mutex.lock()
	var count = min(MAX_INSTANCES_PER_FRAME, _mesh_creation_queue.size())
	for i in range(count):
		var cell = _mesh_creation_queue.pop_front()
		_create_mesh_instance(cell)
		
	# 当队列过长时暂停创建，防止积压
	if _mesh_creation_queue.size() > 50:
		_pause_mesh_creation = true
		print("Mesh creation paused due to large queue")
	
	_mesh_queue_mutex.unlock()

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
		
	for thread in _mesh_thread_pool:
		thread.start(_mesh_worker)
		
	_state = IslandState.OBSERVED

func get_voxelgrid(cell:Vector3) -> VoxelGrid:
	for element in get_cell(cell):
		if element is VoxelGrid:
			return element
	return null

func generate_meshs():
	for cell in cells.keys():
		generate_mesh(cell)

# 生成区块面实例（多线程版）
func generate_mesh(cell: Vector3):
	if _block_Grid_mesh.has(cell) or _pending_mesh_tasks.has(cell):
		return
	
	var voxelgrid = get_voxelgrid(cell)
	if voxelgrid == null:
		return
	
	# 获取相邻区块数据（在主线程完成）
	var neighbors: Array[VoxelGrid] = []
	neighbors.resize(6)
	neighbors[VoxelGridMeshTool.FRONT] = get_voxelgrid(cell+Vector3.FORWARD)
	neighbors[VoxelGridMeshTool.BACK] = get_voxelgrid(cell+Vector3.BACK)
	neighbors[VoxelGridMeshTool.TOP] = get_voxelgrid(cell+Vector3.UP)
	neighbors[VoxelGridMeshTool.BOTTOM] = get_voxelgrid(cell+Vector3.DOWN)
	neighbors[VoxelGridMeshTool.RIGHT] = get_voxelgrid(cell+Vector3.RIGHT)
	neighbors[VoxelGridMeshTool.LEFT] = get_voxelgrid(cell+Vector3.LEFT)
	
	# 创建网格生成任务
	var task = {
		"cell": cell,
		"voxelgrid": voxelgrid,
		"neighbors": neighbors,
		"cell_position": get_cell_position(cell)
	}
	
	# 添加到待处理队列
	_mesh_mutex.lock()
	_pending_mesh_tasks[cell] = task
	_mesh_mutex.unlock()
	
	# 唤醒一个空闲线程
	_mesh_semaphore.post()

# 线程工作函数
func _mesh_worker():
	while true:
		_mesh_semaphore.wait()
		
		# 获取任务
		_mesh_mutex.lock()
		var task = null
		if _pending_mesh_tasks.size() > 0:
			var cell = _pending_mesh_tasks.keys()[0]
			task = _pending_mesh_tasks[cell]
			_pending_mesh_tasks.erase(cell)
		_mesh_mutex.unlock()
		
		if task == null:
			continue
		
		# 实际生成网格（在后台线程）
		var cell_tool = VoxelGridMeshTool.new()
		var mesh = cell_tool.generate_voxelgrid_mesh(
			task.voxelgrid,
			task.neighbors,
			block_types,
			task.cell_position
		)
		
		# 将结果传回主线程
		call_deferred("_on_mesh_generated", task.cell, mesh)

# 主线程处理生成完成的网格
func _on_mesh_generated(cell: Vector3, mesh: ArrayMesh):
	_block_Grid_mesh[cell] = mesh
	
	# 添加到创建队列而不是立即创建
	_mesh_queue_mutex.lock()
	# 如果该区块需要显示，添加到队列
	if _list_Grid_mesh.has(cell) and not _list_Grid_mesh[cell]:
		# 避免重复添加
		if not cell in _mesh_creation_queue:
			_mesh_creation_queue.append(cell)
			
			# 如果之前暂停了，当队列减少到合理大小时恢复
			if _pause_mesh_creation and _mesh_creation_queue.size() < 30:
				_pause_mesh_creation = false
				print("Mesh creation resumed")
	
	_mesh_queue_mutex.unlock()

# 创建网格实例（主线程）
func _create_mesh_instance(cell: Vector3):
	var mesh_node = MeshInstance3D.new()
	mesh_node.name = "%.1f, %.1f, %.1f" % [cell.x, cell.y, cell.z]
	mesh_node.mesh = _block_Grid_mesh[cell]
	mesh_node.position = floatingisland_AABB.position
	mesh_node.material_override = block_types.get_material()
	add_child(mesh_node)
	_list_Grid_mesh[cell] = true

# 根据AABB获取区块（多线程优化版）
func get_cells_deta(aabb:AABB):
	var cells_in_aabb = _get_cells(aabb_global_to_local(aabb))
	
	for cell in cells_in_aabb:
		# 标记需要显示该区块
		if not _list_Grid_mesh.has(cell):
			_list_Grid_mesh[cell] = false
		
		# 如果网格已生成，添加到队列
		if _block_Grid_mesh.has(cell):
			if not _list_Grid_mesh[cell]:
				_mesh_queue_mutex.lock()
				if not cell in _mesh_creation_queue:
					_mesh_creation_queue.append(cell)
				_mesh_queue_mutex.unlock()
		else:
			# 触发网格生成（如果尚未开始）
			generate_mesh(cell)
