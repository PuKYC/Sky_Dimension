extends Node3D

@onready var root_connect = get_tree().get_first_node_in_group("root_connect")
@onready var world_manager := $World_manager

@export var block_type: Block_Types

var player_posi: Vector3
var th = Thread.new()

func _ready() -> void:
	root_connect.ready.connect(start_run)
	block_type = Block_Types.new()
	block_type.add_block(1, "block", Vector3(1,1,1), ["res://World/block_png/leaves_birch_opaque.png"], 0)
	block_type.pack_t_array()
	
	world_manager.block_types = block_type

# 确保所有节点初始化完成再运行
func start_run():
	pass

func _on_camera_position_position_update(posi: Vector3) -> void:
	var cell_posi = posi/32
	if cell_posi != player_posi:
		world_manager.location_grid(posi)
		player_posi = cell_posi
	
