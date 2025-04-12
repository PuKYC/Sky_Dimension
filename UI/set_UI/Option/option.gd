extends HBoxContainer

var is_name:String
var value

@onready var l_name = $Label
@onready var input = $TabContainer
@onready var button = $TabContainer/Button
@onready var check = $TabContainer/CheckButton
@onready var root_connect = get_tree().get_first_node_in_group("root_connect")

func add_input_type(is_set_name: String, v):
	is_name = is_set_name
	l_name.text = is_set_name
	value = v
	match typeof(v):
		TYPE_STRING:
			input.current_tab = 0
			button.pressed.connect(Callable(root_connect, value))
			
			
		TYPE_BOOL:
			input.current_tab = 1
			check.set_pressed_no_signal(!value)
			
		


func _on_check_button_toggled(toggled_on: bool) -> void:
	value = toggled_on
