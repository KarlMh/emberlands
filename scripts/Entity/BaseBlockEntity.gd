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

# Getters
func get_id() -> int:
	return _id
	
func get_name() -> String:
	return _name

func get_hp() -> int:
	return _hp

func set_hp():
	self._hp = self.get_initial_hp()
	self._pickup_hp = self.get_initial_hp()

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
	
func is_losing_health() -> bool:
	# Returns true if current health is less than the initial health
	return _hp < _initial_hp

func pick_up_block():
	if !_can_be_damaged or _destroyed or _pickup_hp <= 0 or self._hp != self._initial_hp:
		return false  # Block can't be picked up

	# Spawn loader only if it doesn't exist
	if _loader == null:
		_loader = _spawn_loader()

	self._pickup_hp -= 1
	_loader.value = (1.0 - (_pickup_hp / _initial_hp)) * 100  # Update progress

	if self._pickup_hp <= 0:
		self._pickup_hp = 0
		_destroyed = true
		_remove_loader()  # Remove loader when block is fully picked up
		return true  # Block is now picked up

	return false  # Block is in progress of being picked up

	

# Function to spawn the progress bar
func _spawn_loader() -> ProgressBar:
	print("LOAAAAADDDDERRRRR")
	var loader = ProgressBar.new()
	loader.show_percentage = false
	loader.size = Vector2(30, 8)  # Adjust size
	loader.min_value = 0
	loader.max_value = 100
	loader.value = 0  # Start at 0%
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(137, 207, 240, 1.0)  # Bright green bar
	bar_style.corner_radius_top_left = 1
	bar_style.corner_radius_top_right = 1
	bar_style.corner_radius_bottom_left = 1
	bar_style.corner_radius_bottom_right = 1
	loader.add_theme_stylebox_override("fill", bar_style)

	# Set custom color for the progress bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.5)  # Semi-transparent black
	bg_style.corner_radius_top_left = 1
	bg_style.corner_radius_top_right = 1
	bg_style.corner_radius_bottom_left = 1
	bg_style.corner_radius_bottom_right = 1
	loader.add_theme_stylebox_override("background", bg_style)

	# Position it below the block
	var loader_position = _position * 32 + Vector2i(0, 22)  
	loader.position = loader_position
	loader.position.x = (_position.x * 32) + (32 - loader.size.x) / 2


	_parent_node.add_child(loader)
	return loader


# Function to remove the progress bar
func _remove_loader():
	if _loader:
		set_hp()
		_loader.queue_free()  # Remove it from the scene
		_loader = null  # Reset reference

# Reduce HP
func reduce_hp(amount: float, blockLayer: TileMapLayer, breakingLayer: TileMapLayer) -> bool:
	if !_can_be_damaged or _destroyed or self._pickup_hp != self._initial_hp:
		return false  # Block can't be damaged or is already destroyed

	if self._hp == self._initial_hp:
		self._hp -= amount

	self._hp -= 1
	_start_break_animation(blockLayer, breakingLayer, true)  # Start the break animation

	if self._hp <= 0:
		self._hp = 0
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
	var drop_chance = block_data.get("drop_chance", 1.0)
	var alt_drop = block_data.get("alt_drop", null)
	var alt_drop_chance = block_data.get("alt_drop_chance", drop_chance)  # Use main drop chance if not set
	var alt_drop_count = block_data.get("alt_drop_count", 1)  # Default to 1 if not set

	# Primary drop
	if randf() <= drop_chance:
		drops.append(dl.create_item(block_name))

	# Alternate drop (only if an alt_drop exists)
	if alt_drop and randf() <= alt_drop_chance:
		for i in range(alt_drop_count):  # Drop multiple alt drops based on alt_drop_count
			drops.append(dl.create_item(alt_drop))

	return drops
