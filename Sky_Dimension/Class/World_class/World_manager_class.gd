## 空岛数据管理类
extends GridPartition
class_name World_manager

var location:int
var cellsState: Dictionary
var location_floatingisland:Dictionary
var block_types: Block_Types

# 线程控制相关变量
var generation_thread: Thread
var generation_queue: Array = [] # 格式: [distance_squared, floatingisland, cell]
var generation_mutex: Mutex = Mutex.new()
var generated_meshes: Array = [] # 存储生成完成的网格
var active: bool = true
var max_tasks_per_frame: int = 2 # 每帧最大处理任务数

func _init() -> void:
	super._init(Vector3.ONE*4096)
	cellsState = {}
	location = 4000
	generation_thread = Thread.new()
	generation_thread.start(_thread_function)

func _exit_tree():
	active = false
	generation_thread.wait_to_finish()

func _process(_delta):
	generation_mutex.lock()
	var tasks_to_process = min(max_tasks_per_frame, generated_meshes.size())
	for i in range(tasks_to_process):
		var mesh_data = generated_meshes.pop_front()
		_create_mesh_instance(mesh_data)
	generation_mutex.unlock()

# 创建网格实例
func _create_mesh_instance(mesh_data: Dictionary):
	var floatingisland: FloatingIsland = mesh_data["island"]
	var cell: Vector3 = mesh_data["cell"]
	var mesh = mesh_data["mesh"]
	
	# 创建网格实例节点
	var mesh_node = MeshInstance3D.new()
	mesh_node.name = "%.1f, %.1f, %.1f" % [cell.x, cell.y, cell.z]
	mesh_node.mesh = mesh
	mesh_node.position = floatingisland.get_cell_position(cell)
	mesh_node.material_override = block_types.get_material()
	
	# 添加到空岛节点
	floatingisland.add_child(mesh_node)
	
	# 更新状态记录
	floatingisland._list_Grid_mash[cell] = mesh_node
	floatingisland._block_Grid_mash[cell] = mesh

func _thread_function():
	while active:
		generation_mutex.lock()
		
		if generation_queue.size() > 0:
			# 按距离排序（最近优先）
			generation_queue.sort_custom(func(a, b): return a[0] < b[0])
			
			# 获取最近的任务
			var task = generation_queue.pop_front()
			var distance_sq = task[0]
			var floatingisland: FloatingIsland = task[1]
			var cell: Vector3 = task[2]
			
			generation_mutex.unlock()
			
			# 生成网格数据
			var mesh = floatingisland.generate_mesh_data(cell)
			if mesh:
				generation_mutex.lock()
				generated_meshes.append({
					"island": floatingisland,
					"cell": cell,
					"mesh": mesh
				})
				generation_mutex.unlock()
		else:
			generation_mutex.unlock()
			OS.delay_msec(50) # 避免忙等待

func add_floatingisland(aabb:AABB):
	var floatingisland = FloatingIsland.new()
	floatingisland.position = aabb.position
	floatingisland.block_types = block_types
	floatingisland.floatingisland_AABB = aabb
	floatingisland.name = str(hash(floatingisland))
	insert(floatingisland, aabb)

# 生成区块中的空岛占位符
func generate_grid(cell:Vector3):
	if not cellsState.has(cell):
		for x in 2:
			for z in 2:
				add_floatingisland(AABB(get_cell_position(cell) + Vector3(x, 0, z)*2000, Vector3.ONE*512))
		cellsState[cell] = true

func generate_grids(cells:PackedVector3Array):
	for grid in cells:
		generate_grid(grid)

func location_grid(pos:Vector3):
	var aabb = AABB(Vector3.ZERO, location*Vector3.ONE)
	var big_aabb = AABB(Vector3.ZERO, location*Vector3.ONE + Vector3.ONE*4096*2)
	
	aabb.position = pos - aabb.get_center()
	big_aabb.position = pos - big_aabb.get_center()
	
	generate_grids(_get_cells(big_aabb))
	
	for floatingisland in query(aabb):
		var f_aabb = aabb.intersection(floatingisland.floatingisland_AABB)
		if f_aabb.size == Vector3.ZERO:
			continue
		
		floatingisland.generate()
		
		# 获取需要生成的区块
		var cells_to_generate = floatingisland._get_cells(
			floatingisland.aabb_global_to_local(f_aabb)
		)
		
		# 添加到生成队列
		generation_mutex.lock()
		for cell in cells_to_generate:
			# 如果已经生成了网格，则跳过
			if floatingisland._block_Grid_mash.has(cell):
				continue
				
			# 计算区块中心的世界坐标
			var cell_center = floatingisland.get_cell_position(cell) + floatingisland.cell_size * 0.5
			var world_pos = floatingisland.floatingisland_AABB.position + cell_center
			var distance_sq = world_pos.distance_squared_to(pos)
			
			generation_queue.append([distance_sq, floatingisland, cell])
		generation_mutex.unlock()
		
		if not location_floatingisland.has(floatingisland):
			add_child(floatingisland)
			location_floatingisland[floatingisland] = true
