## 管理游戏场景渲染的类
## 
## 使用一个MultiMeshInstance3D来创建近景
## 使用计算着色器剔除MultiMeshInstance3D中的不可见区块
## 使用多个MeshInstance3D创建远景LOD
extends Node3D
class_name Render

@onready var block_types: Block_Types:
	set(block_type):
		block_types = block_type
		
var main_multimeshinstance3D: MultiMeshInstance3D = MultiMeshInstance3D.new()

class VoxelGrids_Render_Process:
	var _input_keys: Array
	var _input_data: Dictionary
	var _output_floatingisland_blocks_dictionary: Dictionary
	var mutex = Mutex.new()

	func _init(floatingisland_blocks_dictionary: Dictionary) -> void:
		_input_data = floatingisland_blocks_dictionary
		_input_keys = _input_data.keys()

	func voxelgrid_process_thread(index):
		var key = _input_keys[index]
		var value = _input_data[key]
		
		var voxelgrid_process_array
		
		mutex.lock()
		_output_floatingisland_blocks_dictionary[key] = value
		mutex.unlock()

	func voxelgrids_process():
		var task_id = WorkerThreadPool.add_group_task(
			self.voxelgrid_process_thread,
			_input_keys.size()
		)
		WorkerThreadPool.wait_for_group_task_completion(task_id)

func _ready() -> void:
	add_child(main_multimeshinstance3D)
	main_multimeshinstance3D.multimesh = load("res://World/block_multi_mesh.tres")

func generate_mesh(floatingisland_blocks_dictionary: Dictionary):
	var voxelgrids = VoxelGrids_Render_Process.new(floatingisland_blocks_dictionary)
	voxelgrids.voxelgrids_process()
	
