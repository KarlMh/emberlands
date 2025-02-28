extends Object
class_name BaseBlock

# Properties
var _id: int
var _name: String
var _hp: float
var _initial_hp: float
var _position: Vector2i
var _gems_to_drop: int
var _destroyed: bool = false
var _can_be_damaged: bool = true
var _is_interactive: bool = false
var _parent_node: Node

# Animation properties
var _tileset_source_id: int = 0
var _block_timers: Dictionary = {}

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

# Reduce HP
func reduce_hp(amount: float, blockLayer: TileMapLayer, breakingLayer: TileMapLayer) -> bool:
	if !_can_be_damaged or _destroyed:
		return false  # Block can't be damaged or is already destroyed

	if self._hp == self._initial_hp:
		self._hp -= amount

	self._hp -= 1
	_start_break_animation(blockLayer, breakingLayer)  # Start the break animation

	if self._hp <= 0:
		self._hp = 0
		_destroyed = true
		return true  # Block is now destroyed

	return false  # Block is damaged but not destroyed

# Animation Handling
func _start_break_animation(blockLayer: TileMapLayer, breakingLayer: TileMapLayer):
	if not breakingLayer:
		return

	if _destroyed:
		breakingLayer.erase_cell(_position)
		return

	var total_frames = 6
	var damage_index = clamp(int(((_initial_hp - _hp) / float(_initial_hp)) * total_frames), 0, total_frames)
	breakingLayer.set_cell(_position, _tileset_source_id, Vector2i(damage_index, 0))

	# If a timer already exists, reset it instead of creating a new one
	if _block_timers.has(_position):
		_block_timers[_position].start()  # Restart existing timer
		return

	# Create and start a new timer if it doesn't exist
	var erase_timer = Timer.new()
	erase_timer.wait_time = 4.0
	erase_timer.one_shot = true
	erase_timer.timeout.connect(_on_erase_timeout.bind(breakingLayer))
	_parent_node.add_child(erase_timer)

	erase_timer.start()
	_block_timers[_position] = erase_timer

func _on_erase_timeout(breakingLayer: TileMapLayer):
	if breakingLayer:
		breakingLayer.erase_cell(_position)
		self.set_hp()

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
