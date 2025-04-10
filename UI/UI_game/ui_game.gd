extends Root_gui

signal open_set_op


func _on_set_released() -> void:
	emit_signal("open_set_op")
	
