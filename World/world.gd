extends Node3D

@onready var root_connect = get_tree().get_first_node_in_group("root_connect")
@onready var render = $Render

@export var block_types: Block_Types

var world_manager: World_manager
var player_posi: Vector3

func _ready() -> void:
	root_connect.ready.connect(start_run)
	block_types = Block_Types.new()
	block_types.add_block(1, "block", Vector3(1,1,1), ["res://icon.svg"], 0)
	
	world_manager = World_manager.new(block_types)

# 确保所有节点初始化完成再运行
func start_run():
	pass

func _on_camera_position_position_update(posi: Vector3) -> void:
	var cell_posi = world_manager.has_point(posi)
	if cell_posi != player_posi:
		render.add_mesh(world_manager.location_grid(posi))
		#print(world_manager.location_grid(posi))
		render.generate_mash()
		player_posi = cell_posi
	
