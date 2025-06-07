## 空岛数据管理类
extends GridPartition
class_name World_manager

var location:int
var cellsState: Dictionary
var location_floatingisland:Dictionary
var block_types: Block_Types

func _init() -> void:
	super._init(Vector3.ONE*4096)
	cellsState = {}
	location = 4000

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
		for x in 1:
			for z in 1:
				add_floatingisland(AABB(get_cell_position(cell) + Vector3(x, 0, z)*1500, Vector3.ONE*512))
		
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
		# print(aabb,  " ", floatingisland.floatingisland_AABB, " ", aabb.abs().intersection(floatingisland.floatingisland_AABB))
		if f_aabb.size == Vector3.ZERO:
			#print(floatingisland.position)
			continue
		floatingisland.generate()
		floatingisland.generate_meshs()
		floatingisland.get_cells_deta(f_aabb)
		if not location_floatingisland.has(floatingisland):
			add_child(floatingisland)
			#print("add ", floatingisland)
			location_floatingisland[floatingisland] = true
		
