extends CanvasLayer

var UI_game = preload("res://UI/UI_game/UI_game.tscn").instantiate()
var set_UI = preload("res://UI/set_UI/set_UI.tscn").instantiate()

func _ready() -> void:
	add_child(UI_game)
	add_child(set_UI)
	set_UI.visible = false
	UI_game.open_set_op.connect(is_open_set)
	set_UI.exit_set_op.connect(is_exit_set)
	
func is_open_set():
	UI_game.GUI_hide()
	
	set_UI.GUI_show()

func is_exit_set():
	UI_game.GUI_show()
	
	set_UI.GUI_hide()
