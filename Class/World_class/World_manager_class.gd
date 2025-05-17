## 空岛数据管理类
extends GridPartition
class_name World_manager

var location:int
var cellsState: Dictionary
var block_types: Block_Types

func _init(block_type: Block_Types) -> void:
	super._init(Vector3.ONE*4096)
	block_types = block_type
	cellsState = {}
	location = 128

func add_floatingisland(aabb:AABB):
	insert(FloatingIsland.new(aabb, block_types), aabb)

# 生成区块中的空岛占位符
func generate_grid(cell:Vector3):
	if not cellsState.has(cell):
		add_floatingisland(AABB(cell, Vector3.ONE*128))
		
		cellsState[cell] = true
	

func generate_grids(cells:PackedVector3Array):
	for grid in cells:
		generate_grid(grid)

func location_grid(position:Vector3) -> Dictionary:
	var aabb = AABB(Vector3.ZERO, location*Vector3.ONE)
	var big_aabb = AABB(Vector3.ZERO, location*Vector3.ONE + Vector3.ONE*4096*2)
	var locationgrid:Dictionary 
	
	aabb.position = position - aabb.get_center()
	big_aabb.position = position - big_aabb.get_center()
	
	generate_grids(_get_cells(big_aabb))
	
	for floatingisland in query(aabb):
		floatingisland.generate()
		floatingisland.generate_mesh(Vector3.ZERO)
		locationgrid[floatingisland] = floatingisland.get_cells_deta(aabb.intersection(floatingisland.floatingisland_AABB))
		
		
		
	return locationgrid
