extends Object
class_name BaseBlock

# Properties
var _id: int
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
	print("Starting break animation for:", _position)

	if not breakingLayer:
		print("ERROR: breakingLayer is null!")
		return

	if _destroyed:
		breakingLayer.erase_cell(_position)
		return

	var total_frames = 6
	var damage_index = clamp(int(((_initial_hp - _hp) / float(_initial_hp)) * total_frames), 0, total_frames)
	breakingLayer.set_cell(_position, _tileset_source_id, Vector2i(damage_index, 0))

	if _block_timers.has(_position):
		return

	var erase_timer = Timer.new()
	erase_timer.wait_time = 5.0
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

# Drop Items (Overridden by subclasses)
func drop_block() -> Array:
	if not _destroyed:
		return []

	var drops = []
	var block_name = dl.get_item_name_by_id(_id)

	if block_name:
		# Get block data using the name from DataLoader
		var block_data = dl._get(block_name)

		if block_data != null:
			# Handle both primary and alternate drops (drop_chance is used for both)
			var drop_chance = block_data.get("drop_chance", 1.0)
			var alt_drop = block_data.get("alt_drop", null)

			# Primary drop
			if randf() <= drop_chance:
				drops.append(dl.create_item(block_name))

			# Alternate drop (if exists)
			if alt_drop and randf() <= drop_chance:
				drops.append(dl.create_item(alt_drop))

			# Handle alt_drop if it exists, but no separate alt_drop_chance
			if alt_drop and not randf() <= drop_chance:
				print("Alternate drop failed for", alt_drop)
		else:
			print("Error: Block data not found for ID", _id)
	else:
		print("Error: Block name not found for ID", _id)

	return drops
