extends Button

@onready var player = get_tree().get_root().find_child("player", true, false)
@onready var craft_item_list = get_tree().get_root().find_child("craft_item_list", true, false)

var dl = DataLoader

func _ready() -> void:
	# Check if the craft_item_list node is valid
	if craft_item_list == null:
		print("Error: craft_item_list node not found!")
		return

func _on_pressed() -> void:
	# Check if craft_item_list is valid
	var selected_index = craft_item_list.get_selected_items()
	if !selected_index:
		return
	var selected_item_name = craft_item_list.get_item_text(selected_index[0])  # Get the name of the selected item
	if player.interact_craft() or dl._get(selected_item_name)["crafting_tier"] == 0:
		if craft_item_list != null:
			if selected_index.size() > 0:  # Ensure at least one item is selected
				print("Selected item:", selected_item_name)  # Debugging line

				# Call the player's craft_item function with the selected item's name
				player.craft_item(selected_item_name, 1)
			else:
				print("No item selected!")  # Handle case where no item is selected
		else:
			print("craft_item_list is null, unable to process selection.")
	else:
		print("not next to crafting table")
