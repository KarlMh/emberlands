extends Object
class_name BaseBlockEntity

# Properties
var _id: int
var _name: String
var _hp: float
var _initial_hp: float
var _pickup_hp: float
var _position: Vector2i
var _gems_to_drop: int
var _destroyed: bool = false
var _can_be_damaged: bool = true
var _is_interactive: bool = false
var _parent_node: Node
var _canvas_node: Node

# Animation properties
var _tileset_source_id: int = 0
var _block_timers: Dictionary = {}
var _loader: ProgressBar = null  # Track the loader instance

var dl = DataLoader


# Constructor
func _init(id: int, position: Vector2i, parent_node: Node, can_be_damaged: bool):
	self._id = id
	self._name = dl.get_item_name_by_id(id)
	self._position = position
	self._destroyed = false
	self._can_be_damaged = can_be_damaged
	self._parent_node = parent_node
	_canvas_node = self._parent_node.get_tree().get_root().find_child("CanvasLayer2", true, false)

# Getters
func get_id() -> int:
	return _id
	
func get_name() -> String:
	return _name

func get_hp() -> int:
	return _hp

func set_hp():
	self._hp = self.get_initial_hp()

func get_initial_hp() -> int:
	return _initial_hp

func get_position() -> Vector2i:
	return _position

func get_gems_to_drop() -> int:
	return _gems_to_drop

func is_destroyed() -> bool:
	return _destroyed

func can_be_damaged() -> bool:
	return _can_be_damaged
	
func get_loader() -> ProgressBar:
	return _loader
	
func is_being_picked_up() -> bool:
	# Returns true if current health is less than the initial health
	return _pickup_hp < _initial_hp

func pick_up_block():
	if !can_be_damaged() or _destroyed or _pickup_hp <= 0 or self._hp != self._initial_hp:
		return false  # Block can't be picked up

	# Spawn loader only if it doesn't exist
	if _loader == null:
		_loader = _spawn_loader()

	self._pickup_hp -= 1
	_loader.value = (1.0 - (_pickup_hp / _initial_hp)) * 100  # Update progress

	if self._pickup_hp <= 0:
		self._pickup_hp = 0
		
		var interactive_block = self as InteractiveBlockEntity
		if interactive_block:
			interactive_block.despawn_interactive_button()
		
		_destroyed = true
		_remove_loader()  # Remove loader when block is fully picked up
		return true  # Block is now picked up

	return false  # Block is in progress of being picked up

	

# Function to spawn the progress bar
func _spawn_loader() -> ProgressBar:
	print("LOAAAAADDDDERRRRR")
	
	var loader = ProgressBar.new()
	loader.show_percentage = false
	loader.size = Vector2(32, 32)  # Slightly larger for visibility
	loader.min_value = 0
	loader.max_value = 70
	loader.value = 0  # Start at 0%

	# Create the fill style (progress bar itself)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(229 / 255.0, 255 / 255.0, 204 / 255.0)
	fill_style.corner_radius_top_left = 1
	fill_style.corner_radius_top_right = 1
	fill_style.corner_radius_bottom_left = 1
	fill_style.corner_radius_bottom_right = 1
	loader.add_theme_stylebox_override("fill", fill_style)

	# Create the background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0)  # Darker semi-transparent background
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	loader.add_theme_stylebox_override("background", bg_style)

	# Center the progress bar below the block
	var block_size = 32
	var loader_position = _position * block_size
	loader.position = loader_position

	# Add to parent node
	_parent_node.add_child(loader)
	
	print(_parent_node)
	
	return loader


# Function to remove the progress bar
func _remove_loader():
	if _loader:
		self._pickup_hp = self.get_initial_hp()
		_loader.queue_free()  # Remove it from the scene
		_loader = null  # Reset reference

func reduce_hp(amount: float, blockLayer: TileMapLayer, breakingLayer: TileMapLayer) -> bool:
	if !_can_be_damaged or _destroyed or self._pickup_hp != self._initial_hp:
		return false  # Block can't be damaged or is already destroyed
	
	_remove_loader()
	
	if self._hp == self._initial_hp:
		self._hp -= amount

	self._hp -= 1
	_start_break_animation(blockLayer, breakingLayer, true)  # Start the break animation

	if self._hp <= 0:
		self._hp = 0

		# If it's an InteractiveBlockEntity, call despawn_interactive_button()
		var interactive_block = self as InteractiveBlockEntity
		if interactive_block:
			interactive_block.despawn_interactive_button()
		
		_destroyed = true
		return true  # Block is now destroyed

	return false  # Block is damaged but not destroyed


# Animation Handling
func _start_break_animation(blockLayer: TileMapLayer, breakingLayer: TileMapLayer, breaking: bool):
	if not breakingLayer:
		return

	if _destroyed:
		breakingLayer.erase_cell(_position)
		return

	var total_frames = 6
	var damage_index = clamp(int(((_initial_hp - _hp) / float(_initial_hp)) * total_frames), 0, total_frames)
	
	if breaking:
		breakingLayer.set_cell(_position, _tileset_source_id, Vector2i(damage_index, 0))

	# If a timer already exists, reset it instead of creating a new one
	if _block_timers.has(_position):
		_block_timers[_position].start()  # Restart existing timer
		return

	# Create and start a new timer if it doesn't exist
	var erase_timer = Timer.new()
	var waiting_time = 4.0 if breaking else 0.0
	
	erase_timer.wait_time = waiting_time
	erase_timer.one_shot = true
	erase_timer.timeout.connect(_on_erase_timeout.bind(breakingLayer, breaking))
	_parent_node.add_child(erase_timer)

	erase_timer.start()
	_block_timers[_position] = erase_timer

func _on_erase_timeout(breakingLayer: TileMapLayer, breaking: bool):
	if breakingLayer:
		if breaking:
			breakingLayer.erase_cell(_position)
		self.set_hp()
		_remove_loader()

	if _block_timers.has(_position):
		_block_timers[_position].queue_free()
		_block_timers.erase(_position)


func drop_block() -> Array:
	if not _destroyed:
		return []

	var drops = []
	var block_name = dl.get_item_name_by_id(_id)

	if not block_name:
		print("Error: Block name not found for ID", _id)
		return drops  # Return empty if the block name is invalid

	var block_data = dl._get(block_name)

	if not block_data:
		print("Error: Block data not found for", block_name)
		return drops  # Return empty if no block data exists

	# Get drop properties
	var alt_drop = block_data.get("alt_drop", null)
	
	if !alt_drop:
		return drops
		
	var alt_drop_data = dl._get(alt_drop)
	
	if alt_drop_data:
		
		var drop_chance = alt_drop_data.get("drop_chance", 1.0)  # Default to 1.0 (100%) if not specified

		# Random chance check for drops
		if randf() > drop_chance:
			return drops  # No drop if the random chance exceeds drop_chance

	# Alternate drop (only if an alt_drop exists and is a dictionary)
	if alt_drop:
		for item_name in alt_drop.keys():
			# Randomize the number of items to drop for each alt_drop item based on its count
			var drop_amount = randi() % (int(alt_drop[item_name]) + 1)  # Random number of items between 0 and the count for that item
			for i in range(drop_amount):  # Drop the random amount of items
				drops.append(dl.create_item(item_name))

	return drops
