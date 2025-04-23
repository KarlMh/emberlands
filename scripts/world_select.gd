extends Control

@onready var world_name_input = $WorldSelectPanel/WorldSelectVBoxContainer/InputWorldName
@onready var multiplayer_manager = $MultiplayerManager

func _on_join_world_button_pressed():
	var world_name = world_name_input.text.strip_edges()
	if world_name != "":
		multiplayer_manager.start_multiplayer(world_name, false)  # Call the multiplayer manager to start hosting/joining
		print("World selected:", world_name)
	else:
		print("Please enter a world name.")


func _on_create_world_button_pressed() -> void:
	var world_name = world_name_input.text.strip_edges()
	if world_name != "":
		multiplayer_manager.start_multiplayer(world_name, true)  # Call the multiplayer manager to start hosting/joining
		print("World selected:", world_name)
	else:
		print("Please enter a world name.")
