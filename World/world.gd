extends Node3D

@onready var root_connect = get_tree().get_first_node_in_group("root_connect")
@onready var render: Render = $Render
@export var block_types: Block_Types
var world_manager: World_manager = World_manager.new()
var location: Location = Location.new(Vector3.ONE*128)

func _ready() -> void:
	world_manager.generate_floatingisland(Vector3.ZERO, Vector3.ONE*128)
	root_connect.ready.connect(start_run)

# 确保所有节点初始化完成再运行
func start_run():
	# 接收更新空岛列表的信号
	location.location_floatingisland_updeta.connect(render.generate_mesh)
	# 启动监测岛屿列表函数
	start_location_update()

# 每一秒更新空岛列表
func start_location_update():
	var location_time = Timer.new()
	location_time.wait_time = 2
	location_time.autostart = true
	
	# 使用 lambda 确保每次触发时动态调用
	location_time.timeout.connect(
		func():
			location.location_update(root_connect.get_player_position(), world_manager)
	)
	
	add_child(location_time)
