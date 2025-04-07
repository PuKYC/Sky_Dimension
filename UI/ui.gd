extends CanvasLayer

var UI_game = preload("res://UI/TouchGameControl/UI_game.tscn").instantiate()
var set_UI = preload("res://UI/set_UI/set_UI.tscn").instantiate()

func _ready() -> void:
	add_child(UI_game)
	add_child(set_UI)
	set_UI.visible = false
	UI_game.open_set_op.connect(is_open_set)
	
func is_open_set():
	UI_game.GUI_hide()
	
	set_UI.visible = true
	
	
