extends ScrollContainer

@onready var list = $VBoxContainer

func add_option(options: Dictionary):
	for option_name in options:
		var option = load("res://UI/set_UI/Option/option.tscn").instantiate()
		list.add_child(option)
		
		option.add_input_type(option_name, options[option_name])
