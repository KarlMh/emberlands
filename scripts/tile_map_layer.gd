extends TileMapLayer  # Ensure this is TileMapLayer, NOT TileMap

const WORLD_WIDTH = 100
const WORLD_HEIGHT = 50
const TILE_SIZE = 32  # Adjust this based on your game

var spawn_tile = null

var block_entities = {}
var bg_entities = {}

var dl = DataLoader

@onready var blockLayer = get_tree().get_root().find_child("blockLayer", true, false)
@onready var bg_layer = get_tree().get_root().find_child("backgroundLayer", true, false)

@onready var noise = FastNoiseLite.new()

const BlockEntity = preload("res://scripts/Entity/BlockEntity.gd")
const BackgroundEntity = preload("res://scripts/Entity/BackgroundEntity.gd")

# Timer for cycling through frames
var animation_timer = Timer.new()
var current_frame = 0

func _ready():
	noise.seed = randi()
	noise.frequency = 0.1
	generate_world()
	
	# Set up the animation timer to update the frame every 0.1 seconds
	animation_timer.wait_time = 0.15
	animation_timer.autostart = true
	animation_timer.connect("timeout", Callable(self, "_on_animation_timeout"))
	add_child(animation_timer)
	
func _on_animation_timeout():
	
	# Cycle through the frames in the tile set (6 frames total)
	current_frame = (current_frame + 1) % 6
	# Update the tile map with the new tile (animation)
	set_cell(spawn_tile, dl.SPAWN_POINT["id"], Vector2i(current_frame, 0))


func update_block_below(tile_pos: Vector2i):
	var below_pos = tile_pos + Vector2i(0, 1)  # Position of the block below

	# Ensure the below position is within world bounds
	if below_pos.y >= WORLD_HEIGHT:
		return
	
	var below_id = get_cell_source_id(below_pos)
	var above_id = get_cell_source_id(tile_pos)

	# If placing a block above a dirt block, turn it into deep dirt
	if below_id == dl.BLOCK_DIRT["id"] and above_id != dl.EMPTY["id"]:
		set_cell(below_pos, dl.BLOCK_DEEP_DIRT["id"], Vector2i(0, 0))
		block_entities[below_pos] = BlockEntity.new(dl.BLOCK_DEEP_DIRT["id"], below_pos, self, true)

	# If deep dirt is exposed to air (no block above), turn it back into dirt
	elif below_id == dl.BLOCK_DEEP_DIRT["id"] and above_id == dl.EMPTY["id"]:
		set_cell(below_pos, dl.BLOCK_DIRT["id"], Vector2i(0, 0))
		block_entities[below_pos] = BlockEntity.new(dl.BLOCK_DIRT["id"], below_pos, self, true)


func get_block_name_at_position(pos):
	return block_entities[pos].get_name()


func generate_world():
	randomize()

	var dirt_start_y = WORLD_HEIGHT / 2
	var cave_start_y = WORLD_HEIGHT - 1
	var max_cave_height = 10

	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1

	var cave_path = []
	var cave_y = cave_start_y - randi() % max_cave_height

	for x in range(WORLD_WIDTH):
		cave_y = clamp(cave_y + randi() % 3 - 1, cave_start_y - max_cave_height, cave_start_y)
		cave_path.append(Vector2i(x, cave_y))

	var final_cave_tiles = []
	for tile in cave_path:
		for offset_x in range(-2, 3):
			for offset_y in range(-1, 2):
				var new_tile = Vector2i(tile.x + offset_x, tile.y + offset_y)
				if new_tile.x >= 0 and new_tile.x < WORLD_WIDTH and new_tile.y >= 0 and new_tile.y < WORLD_HEIGHT:
					final_cave_tiles.append(new_tile)

	for x in range(WORLD_WIDTH):
		for y in range(WORLD_HEIGHT + 10):
			var tile_pos = Vector2i(x, y)

			if y >= WORLD_HEIGHT - 1 and x != 0 and x != WORLD_WIDTH - 1:
				set_cell(tile_pos, dl.BLOCK_BEDROCK["id"], Vector2i(0, 0))
				block_entities[tile_pos] = BlockEntity.new(dl.BLOCK_BEDROCK["id"], tile_pos, self, false)
				continue

			elif x == 0 or x == WORLD_WIDTH - 1 or y == 0:
				set_cell(tile_pos, dl.BLOCK_BEDROCK["id"], Vector2i(0, 0))
				block_entities[tile_pos] = BlockEntity.new(dl.BLOCK_BEDROCK["id"], tile_pos, self, false)
				continue

			elif tile_pos in final_cave_tiles:
				erase_cell(tile_pos)
				block_entities[tile_pos] = BlockEntity.new(dl.EMPTY["id"], tile_pos, self, false)

				if randi() % 100 < 8:
					if is_adjacent_to_solid(tile_pos):
						set_cell(tile_pos, dl.BLOCK_MAGMA["id"], Vector2i(0, 0))
						block_entities[tile_pos] = BlockEntity.new(dl.BLOCK_MAGMA["id"], tile_pos, self, true)

			elif y >= dirt_start_y:
				var is_surface_dirt = y == dirt_start_y

				if is_surface_dirt:
					set_cell(tile_pos, dl.BLOCK_DIRT["id"], Vector2i(0, 0))
					block_entities[tile_pos] = BlockEntity.new(dl.BLOCK_DIRT["id"], tile_pos, self, true)

					if randi() % 100 < 4:
						generate_tree(tile_pos + Vector2i(0, -1))

				else:
					if randi() % 100 < 5:
						set_cell(tile_pos, dl.BLOCK_STONE["id"], Vector2i(0, 0))
						block_entities[tile_pos] = BlockEntity.new(dl.BLOCK_STONE["id"], tile_pos, self, true)
					else:
						set_cell(tile_pos, dl.BLOCK_DEEP_DIRT["id"], Vector2i(0, 0))
						block_entities[tile_pos] = BlockEntity.new(dl.BLOCK_DEEP_DIRT["id"], tile_pos, self, true)

			else:
				erase_cell(tile_pos)
				block_entities[tile_pos] = BlockEntity.new(dl.EMPTY["id"], tile_pos, self, false)

			if y >= dirt_start_y and x > 0 and x < WORLD_WIDTH - 1:
				bg_layer.set_cell(tile_pos, dl.BACKGROUND_CAVE["id"], Vector2i(0, 0))
				bg_entities[tile_pos] = BackgroundEntity.new(dl.BACKGROUND_CAVE["id"], tile_pos, self, true)

	place_bedrock_spawn(dirt_start_y)
	
	print("World generated with cave background intact.")

func place_bedrock_spawn(dirt_y):
	var valid_positions = []

	# Find all valid positions on the surface dirt layer
	for x in range(1, WORLD_WIDTH - 1):  # Avoid placing at the edges
		var tile_pos = Vector2i(x, dirt_y)

		# Check if the tile is dirt and if there isn't a tree at the position
		if get_cell_source_id(tile_pos) == dl.BLOCK_DIRT["id"] and !is_too_close_to_other_trees(tile_pos):
			valid_positions.append(tile_pos)

	# Place bedrock at a random valid position
	if valid_positions.size() > 0:
		var bedrock_pos = valid_positions[randi() % valid_positions.size()]
		set_cell(bedrock_pos, dl.BLOCK_BEDROCK["id"], Vector2i(0, 0))
		block_entities[bedrock_pos] = BlockEntity.new(dl.BLOCK_BEDROCK["id"], bedrock_pos, self, false)
		print("Placed single bedrock at:", bedrock_pos)
		spawn_tile = bedrock_pos + Vector2i(0, -1)
		set_cell(spawn_tile, dl.SPAWN_POINT["id"], Vector2i(0, 0))
		block_entities[spawn_tile] = BlockEntity.new(dl.SPAWN_POINT["id"], spawn_tile, self, false)
		bg_layer.set_cell(spawn_tile, dl.SPAWN_POINT["id"], Vector2i(0, 0))
		bg_entities[spawn_tile] = BlockEntity.new(dl.SPAWN_POINT["id"], spawn_tile, self, false)



func is_adjacent_to_solid(tile_pos):
	var directions = [
		Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	for direction in directions:
		var neighbor_pos = tile_pos + direction
		if neighbor_pos.x >= 0 and neighbor_pos.x < WORLD_WIDTH and neighbor_pos.y >= 0 and neighbor_pos.y < WORLD_HEIGHT:
			var tile_id = get_cell_source_id(neighbor_pos)
			if tile_id != dl.EMPTY["id"]:
				return true
	return false

func generate_tree(pos, is_planted = false):
	var trunk_height = randi_range(2, 5)
	var was_planted = false

	# Check if it's space for the tree and not too close to others
	if !is_space_for_tree(pos, trunk_height) or is_too_close_to_other_trees(pos):
		return was_planted

	# Set 'was_planted' to true immediately (before any async operation)
	was_planted = true

	# Start tree growth asynchronously, but do not wait for it here
	# Call the function to grow the tree without waiting
	_animate_tree_growth(pos, trunk_height, is_planted)

	# Return immediately
	return was_planted


# Function to handle the tree growth animation (asynchronously)
func _animate_tree_growth(pos, trunk_height, is_planted):
	tree_positions.append(pos)

	# Time between each trunk growth step (for animation)
	var growth_time = 0  # Adjust as per your need

	# Start generating the trunk
	for i in range(trunk_height):
		# If we're animating tree growth, wait for each trunk piece to be placed
		if is_planted:
			# Wait for growth time for each step (delay to animate the trunk)
			await get_tree().create_timer(growth_time * i).timeout

		var trunk_pos = pos + Vector2i(0, -i)
		bg_layer.set_cell(trunk_pos, dl.BACKGROUND_WOOD["id"], Vector2i(0, 0))
		bg_entities[trunk_pos] = BackgroundEntity.new(dl.BACKGROUND_WOOD["id"], trunk_pos, self, true)

	# Now that the trunk is done growing, place leaves
	var top_pos = pos + Vector2i(0, -trunk_height)

	# Wait for animation completion if it's an animated tree growth
	if is_planted:
		await get_tree().create_timer(growth_time * trunk_height).timeout
	else:
		# Instant growth (no wait needed)
		await get_tree().create_timer(0).timeout

	# Generate the leaves above the trunk
	generate_leaves(top_pos + Vector2i(0, -1))



# **Better Leaves - More Natural Shape**
# Better Leaves - More Natural Shape
func generate_leaves(top_pos) -> bool:
	var leaf_pattern = [
		Vector2i(0, 0),        # Top center
		Vector2i(-1, 0), Vector2i(1, 0),        # Middle sides
		Vector2i(-1, -1), Vector2i(1, -1),      # Upper sides
		Vector2i(0, -1), Vector2i(0, 1),        # Top and bottom
		Vector2i(-2, 0), Vector2i(2, 0),        # Outer sides
		Vector2i(-1, 1), Vector2i(1, 1),        # Lower sides
	]

	# Loop through the leaf pattern to place leaves
	for offset in leaf_pattern:
		var leaf_pos = top_pos + offset

		# Ensure the leaf position is within bounds before setting it
		if leaf_pos.x >= 0 and leaf_pos.x < WORLD_WIDTH and leaf_pos.y >= 0 and leaf_pos.y < WORLD_HEIGHT:
			if get_cell_source_id(leaf_pos) != dl.EMPTY["id"] or bg_layer.get_cell_source_id(leaf_pos) != dl.EMPTY["id"]:
				return false
			bg_layer.set_cell(leaf_pos, dl.BACKGROUND_LEAF["id"], Vector2i(0, 0))
			bg_entities[leaf_pos] = BackgroundEntity.new(dl.BACKGROUND_LEAF["id"], leaf_pos, self, true)
	return true

# **Prevents Trees From Growing Too Close**
var tree_positions = []  # Stores tree locations

func is_too_close_to_other_trees(pos):
	for tree_pos in tree_positions:
		if pos.distance_to(tree_pos) < 5:  # At least 3 tiles apart
			return true
	return false


func is_space_for_tree(pos, trunk_height) -> bool:
	# Check trunk space first (must be clear from obstructions)
	for i in range(trunk_height):
		var check_pos = pos + Vector2i(0, -i)

		# Check if the trunk space is clear in both main map and background layers
		if get_cell_source_id(check_pos) != dl.EMPTY["id"] or bg_layer.get_cell_source_id(check_pos) != dl.EMPTY["id"]:
			return false  # Blocked by either a solid tile or a background

	# Now check the space for leaves above the trunk
	var top_pos = pos + Vector2i(0, -trunk_height -1)

	# Define the leaf pattern
	var leaf_pattern = [
		Vector2i(0, 0),        # Top center
		Vector2i(-1, 0), Vector2i(1, 0),        # Middle sides
		Vector2i(-1, -1), Vector2i(1, -1),      # Upper sides
		Vector2i(0, -1), Vector2i(0, 1),        # Top and bottom
		Vector2i(-2, 0), Vector2i(2, 0),        # Outer sides
		Vector2i(-1, 1), Vector2i(1, 1),        # Lower sides
	]

	# Check if all leaf positions are clear (both tilemap and background layers)
	for offset in leaf_pattern:
		var leaf_pos = top_pos + offset

		# Ensure leaf position is within bounds
		if leaf_pos.x < 0 or leaf_pos.x >= WORLD_WIDTH or leaf_pos.y < 0 or leaf_pos.y >= WORLD_HEIGHT:
			return false  # Out of bounds, cannot plant tree

		# Check if the leaf space is clear (no solid tiles or background blocking)
		if get_cell_source_id(leaf_pos) != dl.EMPTY["id"] or bg_layer.get_cell_source_id(leaf_pos) != dl.EMPTY["id"]:
			return false  # Blocked by a solid tile or background

	# If no obstructions found, allow tree planting
	return true





func remove_tree_if_fully_broken(tile_pos: Vector2i):
	for tree_pos in tree_positions:
		if tile_pos.distance_to(tree_pos) < 3:  # Check if breaking a tree part
			var tree_still_exists = false

			# Check if any part of the tree remains
			for i in range(6):  # Look through trunk and leaves
				var check_pos = tree_pos + Vector2i(0, -i)
				if get_cell_source_id(check_pos) == dl.BACKGROUND_WOOD["id"] or get_cell_source_id(check_pos) == dl.BACKGROUND_LEAF["id"]:
					tree_still_exists = true
					break  # Stop checking if we find any tree part

			# If tree is fully gone, remove from tree_positions
			if not tree_still_exists:
				tree_positions.erase(tree_pos)
				print("Tree at", tree_pos, "is fully broken and removed from tree_positions.")
			return  # Exit after handling one tree
