extends GridContainer

var dl = DataLoader
@onready var recipe_label = get_tree().get_root().find_child("recipe_label", true, false)
@onready var craft_button = get_tree().get_root().find_child("craft_button", true, false)

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

	# Loop through craftable items and create buttons
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

			# Create a button for the item
			var button = Button.new()
			button.name = item_name  # Store the item name in the button

			# Set the button icon if available
			if icon:
				button.icon = icon

			# Assuming item_data is an instance of the Item object
			# Access the item_type directly from the Item object
			var item = dl.create_item(item_name)  # Assuming item_data is already the Item object

			if item.item_type == Item.ItemType.TOOL or item.item_type == Item.ItemType.SEED:
		
				button.icon = icon

			# Connect button to function
			button.pressed.connect(_on_item_selected.bind(button))

			# Add button to GridContainer
			add_child(button)

	# Debugging: Print list contents
	print("✅ Craftable items added:", get_child_count())

# Function to handle item selection
func _on_item_selected(button: Button) -> void:
	var item_name = button.name  # Get the stored item name
	craft_button.get_child(0).name = item_name
	
	recipe_label.display_recipe(item_name)
