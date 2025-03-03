extends Button

@onready var player = get_tree().get_root().find_child("player", true, false)
@onready var craft_list = get_tree().get_root().find_child("craft_list", true, false)  # GridContainer containing the buttons

var dl = DataLoader

var name_holder: String

func _ready() -> void:
	# Ensure craft_list is valid
	if craft_list == null:
		print("Error: craft_list node not found!")
		return
	
	# Connect the button's pressed signal to the on_pressed function
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Loop through all the buttons in the GridContainer (craft_list)
	
	var item_name = get_child(0).name  # Get the name of the button (which corresponds to the item name)
	print("Selected item:", item_name)  # Debugging line
	
	if item_name == null:
		return

	# Use the item name to craft the item
	if player.interact_craft() or dl._get(item_name)["crafting_tier"] == 0:
		# Call the player's craft_item function with the selected item's name
		player.craft_item(item_name, 1)
	else:
		print("Not next to crafting table")
	return  # Exit once the selected button is found and processed
	
	# If no button was pressed, handle that case
	print("No item selected!")
