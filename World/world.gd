extends World_manager

@onready var render = $render
@onready var root_connect = get_tree().get_first_node_in_group("root_connect")

var viewable_area_size:int = 128
var location_aabb:AABB
var location_floatingisland:Array

func _ready() -> void:
	generate_floatingisland()
	# 确保start_location_update函数在所有节点初始化后执行
	root_connect.ready.connect(start_location_update)

# 可视范围初始化
func start_location_update():
	location_aabb = AABB(Vector3.ONE*viewable_area_size/-2, Vector3.ONE*viewable_area_size/2)
	location_update(root_connect.get_player_position())

# 更新可视范围内的数据
func location_update(player_posi: Vector3):
	location_aabb.position += player_posi - location_aabb.get_center()
	location_floatingisland = floatingisland_gridpartition.query(location_aabb)
