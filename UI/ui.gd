extends CanvasLayer

var UI_game = preload("res://UI/TouchGameControl/UI_game.tscn").instantiate()

func _ready() -> void:
	add_child(UI_game)
