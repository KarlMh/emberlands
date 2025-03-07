extends GridContainer

var dl = DataLoader
@onready var recipe_label = get_tree().get_root().find_child("recipe_label", true, false)
@onready var craft_button = get_tree().get_root().find_child("craft_button", true, false)

@onready var display_button_template = get_tree().get_root().find_child("inventory_slot", true, false)

func _ready() -> void:
	populate_craftable_items()

func populate_craftable_items() -> void:
	# Get craftable items from the DataLoader
	var item_lists = dl.get_craftable_and_smeltable_items()
	var craftable_items = item_lists["craftable"]

	# Clear existing buttons in the GridContainer
	for child in get_children():
		child.queue_free()  # Remove existing buttons before repopulating

	# Ensure craftable_items list is not empty
	if craftable_items.is_empty():
		print("⚠️ No craftable items found!")

	# Loop through craftable items and create display_buttons
	for item_name in craftable_items:
		var item_data = dl._get(item_name)
		if item_data:
			var icon_path = item_data.get("icon", "")  # Get the icon path
			print(icon_path)
			var icon = null

			# Load icon only if the path is valid
			if icon_path != "" and ResourceLoader.exists(icon_path):
				icon = load(icon_path)
			else:
				print("⚠️ Missing icon for", item_name)

			# Create a new display_button by duplicating the template
			var new_display_button = display_button_template.duplicate()  # Create a copy of the template

			# Set the item name on the new display button (for identification)
			new_display_button.name = item_name

			# Access the TextRect child of the display_button and set the icon texture
			var text_rect = new_display_button.get_child(0)  # Get the TextRect from the button's child
			if text_rect and icon:
				text_rect.texture = icon  # Set the icon texture to the TextRect's texture property

			# Connect the button's pressed signal to the selection handler
			new_display_button.pressed.connect(_on_item_selected.bind(new_display_button))

			# Add the newly created display_button to the GridContainer
			add_child(new_display_button)

	# Debugging: Print list contents
	print("✅ Display buttons added:", get_child_count())

# Function to handle item selection
func _on_item_selected(button: Button) -> void:
	var item_name = button.name  # Get the stored item name
	craft_button.get_child(0).name = item_name
	
	recipe_label.display_recipe(item_name)
