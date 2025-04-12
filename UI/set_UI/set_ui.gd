extends Root_gui

@onready var set_option = $VBoxContainer/main_set/set_options
@onready var set_type = $VBoxContainer/main_set/Panel/set_type

var cfg = ConfigFile.new()
var err = cfg.load("res://UI/set_UI/Development.cfg")

signal exit_set_op

func _on_exit_pressed() -> void:
		emit_signal("exit_set_op")


func _on_set_type_item_clicked(index: int) -> void:
	set_option.current_tab = index


func _ready() -> void:
	# 遍历所有 section
	for section in cfg.get_sections():
			set_type.add_item(section, load("res://icon.svg"))

			var set_option_list = {}
			for option in cfg.get_section_keys(section):
					set_option_list[option] = cfg.get_value(section, option)

			var options = load("res://UI/set_UI/Option/Option_mian.tscn").instantiate()
			set_option.add_child(options)
			options.add_option(set_option_list)
			
	set_type.select(0)
