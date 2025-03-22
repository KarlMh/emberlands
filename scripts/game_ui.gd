extends Control

@onready var SmeltingPanel = get_tree().get_root().find_child("SmeltingPanel", true, false)
@onready var inventory_window = get_tree().get_root().find_child("inventory_window", true, false)
@onready var options = get_tree().get_root().find_child("options", true, false)

func any_ui_shown():
	return SmeltingPanel.visible or inventory_window.visible or options.visible
	
