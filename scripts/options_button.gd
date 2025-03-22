extends Button

@onready var options = get_tree().get_root().find_child("options", true, false)
@onready var canvas = get_tree().get_root().find_child("CanvasLayer", true, false)
@onready var inventory = get_tree().get_root().find_child("inventory_window", true, false)
@onready var SmeltingPanel = get_tree().get_root().find_child("SmeltingPanel", true, false)

var is_visible = false  # Fixed typo from "is_visisble"

func _input(ev):
	if ev is InputEventKey and ev.is_pressed():  # Ensure it's only triggered once per press
		if ev.keycode == KEY_ESCAPE:
			toggle_options()
			
func _on_pressed() -> void:
	toggle_options()
	
func toggle_options():
	is_visible = !is_visible
	options.visible = is_visible
	
	inventory.visible = false
	SmeltingPanel.visible = false
