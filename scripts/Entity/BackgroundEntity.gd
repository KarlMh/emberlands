extends BaseBlockEntity
class_name BackgroundEntity

# Constructor
func _init(id: int, position: Vector2i, parent_node: Node, can_be_damaged: bool):
	super(id, position, parent_node, can_be_damaged)

	# Get the block name based on ID
	var block_name = dl.get_item_name_by_id(id)

	if block_name != "":
		# Fetch block data dynamically using DataLoader and the block name
		var block_data = dl._get(block_name)

		if block_data != null:
			# Set properties using the fetched block data
			self._hp = block_data["hp"]
			self._initial_hp = block_data["hp"]
			self._pickup_hp = self._initial_hp
			self._gems_to_drop = randf_range(block_data["gems"]/2, block_data["gems"])
		else:
			self._hp = 0
			self._initial_hp = 0
			self._gems_to_drop = 0
			print("Warning: Block data not found for block name", block_name)
	else:
		print("Warning: Block ID not mapped to any block name")
