extends Node3D

var block = preload("res://World/block/block.tscn")

func generate():
	add_child(block.instantiate())
	pass
func _ready() -> void:
	generate()
