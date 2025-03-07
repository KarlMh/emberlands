extends BaseBlockEntity
class_name BlockEntity

var _craft = false
var _smelt = false

# Constructor
func _init(id: int, position: Vector2i, parent_node: Node, can_be_damaged: bool):
	super(id, position, parent_node, can_be_damaged)

	# Get the block name based on ID
	var block_name = self._name

	if block_name != "":
		# Fetch block data dynamically using DataLoader and the block name
		var block_data = dl._get(block_name)

		if block_data != null:
			# Set properties using the fetched block data
			self._hp = block_data["hp"]
			self._initial_hp = block_data["hp"]
			self._gems_to_drop = randf_range(randf_range(0, block_data["gems"]/2), block_data["gems"])
			
			# Check if the block is an interactive block
			if is_interactive_block(block_name):
				# Additional logic for interactive blocks, e.g., enable interaction
				self._is_interactive = true
				set_interaction_type()
			else:
				self._is_interactive = false
		else:
			self._hp = 0
			self._initial_hp = 0
			self._gems_to_drop = 0
			print("Warning: Block data not found for block name", block_name)
	else:
		print("Warning: Block ID not mapped to any block name")


# Function to check if the block is interactive
func is_interactive_block(block_name: String) -> bool:
	# Check if the block's ID matches the CRAFTING_TABLE interactive block's ID
	return block_name in dl.game_data['blocks']['interactive_blocks']

# Function to handle interactions with the block
func set_interaction_type() -> void:
	if self._is_interactive:
		if dl.game_data['blocks']['interactive_blocks'][self._name]["interaction_type"] == "craft":
			self._craft = true
		elif dl.game_data['blocks']['interactive_blocks'][self._name]["interaction_type"] == "smelt":
			self._smelt = true 
			
func is_interact() -> bool:
	return self._is_interactive
			
func is_craft() -> bool:
	return self._craft
	
func is_smelt() -> bool:
	return self._smelt	
