extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const TILE_SIZE = 32
const WORLD_WIDTH = 100
const WORLD_HEIGHT = 50
const BLINK_DELAY_MIN = 4.0
const BLINK_DELAY_MAX = 12.0
const TIME_BETWEEN_ACTIONS = 0.4
const BLOCK_PLACEMENT_RANGE = 3

@onready var animated_sprite = $AnimationPlayer
@onready var animated_sprite2 = $AnimationPlayer2
@onready var animated_sprite3 = $AnimationPlayer3
@onready var animated_sprite4 = $AnimationPlayer4

@onready var blockLayer = $"../blockLayer"
@onready var breakingLayer = $"../breakingLayer"
@onready var bg_layer = $"../backgroundLayer"

@onready var dl = DataLoader

@onready var erase_timer = $"../breakingLayer/erase_timer"
@onready var visuals = $visuals
@onready var camera = $Camera2D

@onready var inventory_manager = get_tree().get_root().find_child("slot_container", true, false)
@onready var inventory_window = get_tree().get_root().find_child("inventory_window", true, false)
@onready var options = get_tree().get_root().find_child("options", true, false)

@onready var jump_sound = get_tree().get_root().find_child("jump_sound", true, false)
@onready var break_sound = get_tree().get_root().find_child("break_sound", true, false)
@onready var place_sound = get_tree().get_root().find_child("place_sound", true, false)
@onready var death_sound = get_tree().get_root().find_child("death_sound", true, false)


@onready var seed_planter = preload("res://scripts/seed_planter.gd").new()

const BlockEntity = preload("res://scripts/BlockEntity.gd")
const BackgroundEntity = preload("res://scripts/BackgroundEntity.gd")
const InteractiveBlockEntity = preload("res://scripts/InteractiveBlock.gd")

var blink_timer = 0.0
var can_blink = true
var blink_delay = BLINK_DELAY_MIN
var action_timer = 0.0
var placing_block = false

var mining_power = 0

@export var player_gems: int

func _ready():
	await get_tree().create_timer(0.01).timeout
	
	spawn_player()
	blink_delay = get_blink_delay()
	add_child(seed_planter)
	inventory_manager.add_item(dl.create_item("GOLDEN_PICKAXE"))
	inventory_manager.add_item(dl.create_item("CRAFTING_TABLE")) 

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	
	if not is_frozen:
		handle_jump()
		handle_movement(delta)
		handle_block_actions(delta)
		craft("CRAFTING_TABLE", 1)
		craft("WOODEN_PICKAXE", 1)
	
	move_and_slide()
	handle_animations()
	clamp_player_position()
	handle_blink(delta)


func spawn_player():
	var spawn_tile = blockLayer.spawn_tile
	position = blockLayer.map_to_local(spawn_tile)
	print("Player spawned at:", position)
	
func respawn_player():
	spawn_player()
	if not death_sound.playing:  # Prevent overlapping sounds
		death_sound.play()
	

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if not jump_sound.playing:  # Prevent overlapping sounds
			jump_sound.play()
		animated_sprite.play("jumping")
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.4

func handle_movement(delta: float):
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		# Flip the player's scale.x based on the direction
		if direction < 0:
			visuals.scale.x = -1  # Mirror the player (facing left)
		elif direction > 0:
			visuals.scale.x = 1   # Reset to normal (facing right)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_animations():
	if is_on_floor():
		if abs(velocity.x) > 1:
			animated_sprite.speed_scale = 2
			animated_sprite.play("walking")
		else:
			animated_sprite.play("RESET")
	else:
		if velocity.y < 0:
			animated_sprite.speed_scale = 2
			animated_sprite.play("jumping")
		elif velocity.y > 0:
			animated_sprite4.speed_scale = 2


func clamp_player_position():
	position.x = clamp(position.x, TILE_SIZE, (WORLD_WIDTH - 1) * TILE_SIZE)
	position.y = clamp(position.y, TILE_SIZE, (WORLD_HEIGHT - 1) * TILE_SIZE)

func handle_blink(delta: float):
	blink_timer += delta
	if blink_timer >= blink_delay and is_on_floor():
		can_blink = false
		animated_sprite2.play("blink")
		blink_timer = 0.0
		can_blink = true
		blink_delay = get_blink_delay()

func get_blink_delay() -> float:
	return randf_range(BLINK_DELAY_MIN, BLINK_DELAY_MAX)

func handle_block_actions(delta: float):
	action_timer += delta
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_break")) and !inventory_window.visible and !options.visible:
		animated_sprite3.speed_scale = 1.5
		animated_sprite3.play("hand_movement")
		if action_timer >= TIME_BETWEEN_ACTIONS:
			action_timer = 0
			break_block()
			place_block()


func break_block() -> void:
	if inventory_manager.get_selected_item() == null or inventory_manager.get_selected_item().get_id() != -10:
		return

	var mouse_pos = get_global_mouse_position()
	var tile_pos = blockLayer.local_to_map(mouse_pos)

	if is_within_range(tile_pos):
		# Check foreground block
		if blockLayer.get_cell_source_id(tile_pos) != dl.EMPTY['id']:
			if blockLayer.block_entities.has(tile_pos):
				var block = blockLayer.block_entities[tile_pos]
				var block_id = block.get_id()
				var is_dirt_block = block_id == dl.BLOCK_DIRT["id"] or block_id == dl.BLOCK_DEEP_DIRT["id"]
				if not break_sound.playing:  # Prevent overlapping sounds
						break_sound.play()
				if block.reduce_hp(mining_power, blockLayer, breakingLayer):
					player_gems += block.get_gems_to_drop()
					var dropped_item = block.drop_block()
					if dropped_item:
						for item in dropped_item:
							inventory_manager.add_item(item)
					blockLayer.set_cell(tile_pos, dl.EMPTY['id'])
					blockLayer.block_entities[tile_pos] = BlockEntity.new(dl.EMPTY['id'], tile_pos, self, false)

					# **Only update below if breaking dirt**
					if is_dirt_block:
						blockLayer.update_block_below(tile_pos)

		# Check background block
		elif bg_layer.get_cell_source_id(tile_pos) != dl.EMPTY['id']:
			if blockLayer.bg_entities.has(tile_pos):
				var bg_block = blockLayer.bg_entities[tile_pos]
				var block_id = bg_block.get_id()
				var is_dirt_block = block_id == dl.BLOCK_DIRT["id"] or block_id == dl.BLOCK_DEEP_DIRT["id"]
				if not break_sound.playing:  # Prevent overlapping sounds
					break_sound.play()

				if bg_block.reduce_hp(mining_power, bg_layer, breakingLayer):
					var dropped_item = bg_block.drop_block()
					player_gems += bg_block.get_gems_to_drop()
					if dropped_item:
						for item in dropped_item:
							inventory_manager.add_item(item)
					bg_layer.set_cell(tile_pos, dl.EMPTY['id'])
					blockLayer.bg_entities[tile_pos] = BackgroundEntity.new(dl.EMPTY['id'], tile_pos, self, false)

					# **Only update below if breaking dirt**
					if is_dirt_block:
						blockLayer.update_block_below(tile_pos)

		# Remove tree if fully broken
		blockLayer.remove_tree_if_fully_broken(tile_pos)



func craft_item(item_name: String, quantity: int) -> bool:
	if quantity <= 0:
		print("❌ Error: Invalid craft quantity: ", quantity)
		return false

	# Validate if the item exists
	var item_data = dl._get(item_name)
			
		
	if not item_data:
		print("❌ Error: Item does not exist: ", item_name)
		return false

	# Ensure the item has a crafting recipe
	var recipe = item_data.get("recipe")
	if not recipe:
		print("⚠️ Error: This item cannot be crafted: ", item_name)
		return false

	# ✅ **First Pass: Check if ALL materials are available for the desired quantity**
	for material in recipe:
		var required_amount = recipe[material] * quantity  # Multiply by requested quantity
		var available_amount = inventory_manager.get_item_count(material)

		if available_amount < required_amount:
			print("❌ Not enough ", material, " to craft ", quantity, " x ", item_name)
			print("Missing: ", required_amount - available_amount, " more of ", material)
			return false  # Abort if any material is missing

	# ✅ **Second Pass: Remove the required materials**
	for material in recipe:
		inventory_manager.remove_item(inventory_manager.get_item_by_name(material), recipe[material] * quantity)

	# ✅ **Final Step: Add crafted item(s)**
	for i in range(quantity):
		inventory_manager.add_item(dl.create_item(item_name))

	print("✅ Successfully crafted ", quantity, " x ", item_name)

	return true  # Indicate successful crafting


func craft(item: String, quantity: int):
	if Input.is_action_just_pressed("ui_craft"):
		var nearby_block = check_and_interact_with_nearby_block()
		if nearby_block and nearby_block.get_interaction_type() == "craft":
			craft_item(item, quantity)



func place_block() -> void:
	if inventory_manager.get_selected_item() == null or inventory_manager.get_selected_item().get_id() == -10 or inventory_manager.get_selected_item().is_tool():
		return
	var mouse_pos = get_global_mouse_position()
	var tile_pos = blockLayer.local_to_map(mouse_pos)

	if is_within_range(tile_pos) and is_within_bounds(tile_pos):
		# Determine which layer to use (foreground or background)
		var selected_item = inventory_manager.get_selected_item()
		if selected_item:
			if selected_item.get_id() == dl.SEED_TREE["id"]:
				# Call the seed planter to plant the seed
				seed_planter.plant_seed(tile_pos, selected_item, blockLayer, inventory_manager)
				return

			var target_layer = bg_layer if selected_item.is_background() else blockLayer
			var target_block_entities = blockLayer.bg_entities if selected_item.is_background() else blockLayer.block_entities
			var class_entity
			if selected_item.is_background():
				class_entity = BackgroundEntity
			else: class_entity = BlockEntity if selected_item.is_block() else InteractiveBlockEntity

			# Check the block above to determine whether to place deep dirt or normal dirt
			var tile_above = tile_pos + Vector2i(0, -1)
			var tile_above_id = target_layer.get_cell_source_id(tile_above)
			var is_dirt_block = selected_item.get_id() == dl.BLOCK_DIRT["id"] or selected_item.get_id() == dl.BLOCK_DEEP_DIRT["id"]
			var block_to_place_id = selected_item.get_id()
			if is_dirt_block:
				block_to_place_id = dl.BLOCK_DIRT["id"]  # Default to normal dirt
				if tile_above_id == dl.BLOCK_DIRT["id"] or tile_above_id == dl.BLOCK_DEEP_DIRT["id"]:
					# Transform to deep dirt if there's dirt above
					block_to_place_id = dl.BLOCK_DEEP_DIRT["id"]
			
			# Check if the target tile is empty
			if target_layer.get_cell_source_id(tile_pos) == dl.EMPTY['id']:
				# Place the block
				target_layer.set_cell(tile_pos, block_to_place_id, Vector2i(0, 0))
				target_block_entities[tile_pos] = class_entity.new(
					block_to_place_id,
					tile_pos,
					self,  # parent_node
					true
				)
				
				if is_dirt_block:
					blockLayer.update_block_below(tile_pos)

				# Remove the item from the inventory
				inventory_manager.remove_item(selected_item, 1)

				# Play the placement animation
				animated_sprite3.speed_scale = 1.5
				animated_sprite3.play("hand_movement")
				
				if not place_sound.playing:  # Prevent overlapping sounds
					place_sound.play()

				print("Placed block at position:", tile_pos)
				
				var player_tile_pos = blockLayer.local_to_map(position)
				if tile_pos == player_tile_pos and target_layer != bg_layer:
					freeze()
					await get_tree().create_timer(0.5).timeout
					respawn_player()
					unfreeze()
					print("DEAD!")  # Prevent placing on themselves
				
			else:
				print("Cannot place block: Tile is not empty.")
		else:
			print("Cannot place block: No item selected.")

			
	
# Scaled Manhattan Distance
func is_within_range(tile_pos: Vector2i) -> bool:
	var player_tile_pos = blockLayer.local_to_map(position)
	var distance_x = abs(tile_pos.x - player_tile_pos.x)
	var distance_y = abs(tile_pos.y - player_tile_pos.y)
	
	# Manhattan Distance but with reduced diagonal reach
	return max(distance_x, distance_y) <= BLOCK_PLACEMENT_RANGE and (distance_x + distance_y) <= (BLOCK_PLACEMENT_RANGE + 1)



func is_within_bounds(tile_pos: Vector2i) -> bool:
	return tile_pos.x >= 0 and tile_pos.x < WORLD_WIDTH and tile_pos.y >= 0 and tile_pos.y < WORLD_HEIGHT
	
	
func check_and_interact_with_nearby_block() -> InteractiveBlockEntity:
	var player_tile_pos = blockLayer.local_to_map(position)

	# Iterate over all block entities in the foreground and background layers
	for tile_pos in blockLayer.block_entities.keys():
		if is_within_range_of_block(tile_pos, player_tile_pos):
			var block_entity = blockLayer.block_entities[tile_pos]
			if block_entity is InteractiveBlockEntity:
				return block_entity
	return null


# Helper method to check if a tile is within range of the player
func is_within_range_of_block(tile_pos: Vector2i, player_tile_pos: Vector2i) -> bool:
	var distance_x = abs(tile_pos.x - player_tile_pos.x)
	var distance_y = abs(tile_pos.y - player_tile_pos.y)
	return distance_x <= 3 and distance_y <= 3
	
	
var is_frozen = false  # State to track if the player is frozen

func freeze():
	is_frozen = true
	velocity = Vector2.ZERO  # Stop all movement
	print("❄️ Player is frozen!")

func unfreeze():
	is_frozen = false
	print("🔥 Player is unfrozen!")
