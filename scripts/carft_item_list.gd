extends ItemList

var dl = DataLoader
@onready var recipe_label = get_tree().get_root().find_child("recipe_label", true, false)

func _ready() -> void:
	populate_craftable_items()
	# Connect the item_selected signal to a function
	connect("item_selected", Callable(self, "_on_item_selected"))

func populate_craftable_items() -> void:
	# Get craftable items from the DataLoader
	var item_lists = dl.get_craftable_and_smeltable_items()
	var craftable_items = item_lists["craftable"]

	# Clear existing items in the ItemList (if any)
	clear()

	# Ensure craftable_items list is not empty
	if craftable_items.is_empty():
		print("⚠️ No craftable items found!")

	# Loop through craftable items and add them to the ItemList
	for item_name in craftable_items:
		var item_data = dl._get(item_name)
		if item_data:
			var icon_path = item_data.get("icon", "")  # Get the icon path
			var icon = null

			# Load icon only if the path is valid
			if icon_path != "" and ResourceLoader.exists(icon_path):
				icon = load(icon_path)
			else:
				print("⚠️ Missing icon for", item_name)

			# Add item to ItemList
			add_item(item_data["ig_name"], icon if icon else null)  # Add item with name and icon
			
			sort_items_by_text()

	# Debugging: Print list contents
	print("✅ Craftable items added:", get_item_count())

# Function to handle item selection
func _on_item_selected(index: int) -> void:
	var ig_item_name = get_item_text(index)  # Get the name of the selected item
	var item_name = dl.get_item_name_by_ig_name(ig_item_name)
	recipe_label.display_recipe(item_name)
