extends Panel
class_name TouchControlBase

var is_dragging := false
var touch_index := -1

@onready var root_connect = get_tree().get_first_node_in_group("root_connect")

func _input(event):
	if handle_input(event):
		get_viewport().set_input_as_handled()

func handle_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed and not is_dragging:
			if is_point_in_control_area(event.position):
				start_control(event)
				return true
		elif not event.pressed and event.index == touch_index:
			end_control()
			return true
	
	elif event is InputEventScreenDrag and event.index == touch_index:
		update_control(event)
		return true
	
	return false

func is_point_in_control_area(_position: Vector2) -> bool:
	return control_point_in_area(self, _position)

func control_point_in_area(_node, _position: Vector2) -> bool:
	if _node is TouchScreenButton:
		return Rect2(_node.global_position, _node.texture_normal.get_size()*_node.scale).has_point(_position)
	return Rect2(_node.global_position, _node.size).has_point(_position)

func start_control(event: InputEventScreenTouch):
	touch_index = event.index
	is_dragging = true
	on_control_started(event)

func update_control(event: InputEventScreenDrag):
	on_control_updated(event)

func end_control():
	is_dragging = false
	touch_index = -1
	on_control_ended()

# 需要子类实现的方法
func on_control_started(_event: InputEventScreenTouch):
	pass

func on_control_updated(_event: InputEventScreenDrag):
	pass

func on_control_ended():
	pass
	
