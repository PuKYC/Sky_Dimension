extends Camera3D
class_name Camera

signal position_update(posi: Vector3)

var previous_global_position: Vector3

func _notification(what: int):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var current_global_position = global_position
		if current_global_position != previous_global_position:
			previous_global_position = current_global_position

			emit_signal("position_update", current_global_position)
