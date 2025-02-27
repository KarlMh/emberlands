# SeedPlanter.gd
extends Node2D

@onready var dl = DataLoader

func plant_seed(dirt_pos: Vector2i, selected_item: Item, blockLayer: TileMapLayer, inventory_manager: Control):
	var above_pos = dirt_pos + Vector2i(0, -1)  # Position above the dirt tile

	# Check if the clicked tile is dirt and the tile above it is empty
	if blockLayer.get_cell_source_id(dirt_pos) == dl.BLOCK_DIRT['id'] and blockLayer.get_cell_source_id(above_pos) == dl.EMPTY['id']:
		# Remove the seed from the player's inventory
		if await blockLayer.generate_tree(above_pos, true):
			inventory_manager.remove_item(selected_item, 1)
		print("Planted seed and grew a tree at:", above_pos)
	else:
		print("Cannot plant seed: No dirt block below or space is occupied.")
