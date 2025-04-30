## 管理游戏场景渲染的类
## 
## 使用一个MultiMeshInstance3D来创建近景
## 使用计算着色器剔除MultiMeshInstance3D中的不可见区块
## 使用多个MeshInstance3D创建远景LOD
extends Node3D
class_name Render

var main_multimeshinstance3D: MultiMeshInstance3D = MultiMeshInstance3D.new()

func _ready() -> void:
	add_child(main_multimeshinstance3D)
	main_multimeshinstance3D.multimesh = load("res://World/block_multi_mesh.tres")

func generate_mesh(floatingisland_blocks_dictionary: Dictionary):
	print(floatingisland_blocks_dictionary)
	
	
