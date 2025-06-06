extends Label

var dl = DataLoader  # Assuming you have DataLoader to access the item data

# Function to display the recipe of the item
func display_recipe(item_name: String) -> void:
	# Get item data from DataLoader
	var item_data = dl._get(item_name)
	
	# Check if item exists
	if item_data and item_data.has("recipe"):
		var recipe = item_data["recipe"]
		var recipe_text = "Recipe for " + item_data["ig_name"] + "\n"  # Change font size of title
		
		# Loop through the recipe dictionary and display each item and its count
		for ingredient in recipe.keys():
			var ingredient_name = dl._get(ingredient)["ig_name"]
			var ingredient_count = recipe[ingredient]
			recipe_text += ingredient_name + " x " + str(ingredient_count) + "\n"  # Smaller font for ingredients
		
		# Set the formatted text in the RichTextLabel
		text = recipe_text
	else:
		text = "No recipe available for " + item_data["ig_name"]  # Font size for no recipe message
