extends Node

var game_data = {}

func _ready():
	load_json_data()

func load_json_data():
	var file = FileAccess.open("res://data/game_data.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		game_data = JSON.parse_string(content)
		file.close()
		print("Game data loaded successfully!")
	else:
		print("Failed to load game data")

# Overriding 'get' to automatically retrieve values without calling a method
func _get(item_name):
		# Validate if the item exists
	var item_data = null
	for cat in game_data:
		# Get item from the category directly
		item_data = game_data[cat].get(item_name)
		if item_data:  # If item found, stop the search
			return item_data

		# If not found, iterate through the subcategories of the category
		for subcat in game_data[cat]:
			item_data = game_data[cat][subcat].get(item_name)
			if item_data:  # If item found in subcategory, stop the search
				return item_data

		if item_data:  # Exit outer loop if item is found
			return item_data
	return null

# Method to get the name of an item based on its ID using recursive search
func get_item_name_by_id(id: int) -> String:
	# Start the recursive search from the game_data
	var item_name = recursive_search(game_data, id)
	
	if item_name == "":
		print("Item with ID", id, "not found.")
	
	return item_name  # Return the item name (or empty string if not found)

# Recursive function to search through all levels of categories and subcategories
func recursive_search(data, id: int) -> String:
	if typeof(data) == TYPE_DICTIONARY:  # Ensure data is a dictionary
		for key in data.keys():
			var item_data = data[key]
			# Check if the item has an 'id' property
			if typeof(item_data) == TYPE_DICTIONARY and item_data.has("id") and item_data["id"] == id:
				return key  # Return the name of the item/block/seed
			# Recursively search subcategories
			var result = recursive_search(item_data, id)
			if result != "":
				return result
	return ""




func create_item(name: String) -> Item:
	# Iterate through all categories
	for category in game_data:
		# If the category contains subcategories, iterate through them
		for subcategory in game_data[category]:
			if game_data[category][subcategory].has(name):
				var item_data = game_data[category][subcategory][name]
				
				# Check for transformation
				if item_data.has("transform"):
					var transformed_name = item_data["transform"]
					print("Transforming item:", name, "to", transformed_name)
					return create_item(transformed_name)  # Recursively create the transformed item

				var id = item_data["id"]
				var icon = load(item_data["icon"])  # Load the icon image from the file path

				# Check if the subcategory is "interactive_blocks"
				if subcategory == "interactive_blocks":
					var gems = item_data["gems"]
					var interaction_type = item_data["interaction_type"]
					var hp = item_data["hp"]
					return Item.create_interactive_block(id, name, interaction_type, icon, gems)  # Create Block item

		# Check if the category exists and has the item by name
		if game_data[category].has(name):
			var item_data = game_data[category][name]
			
			# Check for transformation
			if item_data.has("transform"):
				var transformed_name = item_data["transform"]
				print("Transforming item:", name, "to", transformed_name)
				return create_item(transformed_name)  # Recursively create the transformed item

			var id = item_data["id"]
			var icon = load(item_data["icon"])  # Load the icon image from the file path

			# Check if the category is "blocks"
			if category == "blocks":
				# Block-specific data (e.g., gems and hp)
				var gems = item_data["gems"]
				var hp = item_data["hp"]
				return Item.create_block(id, name, icon, gems)  # Create Block item

			# Check if the category is "backgrounds"
			elif category == "backgrounds":
				# Background-specific data (e.g., gems and hp)
				var gems = item_data["gems"]
				var hp = item_data["hp"]
				return Item.create_background_block(id, name, icon, gems)  # Create Background item

			# Check if the category is "items"
			elif category == "items":
				# Item-specific data (e.g., damage)
				var damage = item_data["damage"]
				return Item.create_tool(id, name, icon, damage)  # Create Tool item

			# Check if the category is "seeds"
			elif category == "seeds":
				# Seed-specific data
				return Item.create_seed(id, name, icon)  # Seeds may be treated as special tools or blocks

	# Return null if item is not found
	print("Item not found:", name)
	return null
