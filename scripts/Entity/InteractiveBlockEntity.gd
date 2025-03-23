extends BlockEntity
class_name InteractiveBlockEntity

# New properties specific to interactive blocks
var _interaction_type: String = ""
var interactive_button: Control = null  # Store reference to button

# New properties to hold furnace slot items
var fuel_slot_item: Item = null
var mats_slot_item: Item = null
var final_slot_item: Item = null
var fuel_slot_item_count: int
var mats_slot_item_count: int
var final_slot_item_count: int

var fuel_slot 
var mats_slot
var final_slot

var furnace_slots

var inventory_manager


# Constructor
func _init(id: int, position: Vector2i, parent_node: Node, can_be_damaged: bool):
	super(id, position, parent_node, can_be_damaged)  # Call parent constructor
	
	# Set interaction type if this block is interactive
	if _is_interactive:
		set_interaction_type()
		
	if parent_node:
		fuel_slot = _parent_node.get_tree().get_root().find_child("fuel_slot", true, false)
		mats_slot = _parent_node.get_tree().get_root().find_child("mats_slot", true, false)
		final_slot = _parent_node.get_tree().get_root().find_child("final_slot", true, false)
		inventory_manager = _parent_node.get_tree().get_root().find_child("slot_container", true, false)
		
		furnace_slots = [fuel_slot, mats_slot, final_slot]
		
# Override the function to define the interaction type
func set_interaction_type() -> void:
	if _is_interactive and _name in dl.game_data['blocks']['interactive_blocks']:
		_interaction_type = dl.game_data['blocks']['interactive_blocks'][_name]["interaction_type"]
		if _interaction_type == "craft":
			_craft = true
		elif _interaction_type == "smelt":
			_smelt = true

# Getters for interaction type
func get_interaction_type() -> String:
	return _interaction_type
	
func spawn_interactive_button():
	# Prevent duplicate button spawn
	if interactive_button:
		return

	# Calculate the world position of the block (assuming TileMap uses 32x32 tiles)
	var world_pos = Vector2(_position.x * 32, _position.y * 32)

	# Spawn the button **above** the block
	var button_pos = world_pos + Vector2(4, -24)  # Centered on block

	# Create a new Button node from the scene
	var button_scene = load("res://scenes/SmeltingButtonPanel.tscn")  # Load the scene
	interactive_button = button_scene.instantiate()  # Instantiate the button from the scene

	# Set button position
	interactive_button.position = button_pos

	# Store reference to this block (self) in the button's user data (custom property)
	interactive_button.get_child(0).block_reference = self

	# Connect the button to an interaction function
	interactive_button.connect("pressed", Callable(self, "_on_interact_button_pressed"))

	# Add button to the parent node (assuming parent_node is a Control or CanvasLayer)
	if _parent_node:
		_canvas_node.add_child(interactive_button)

	# Set button position
	interactive_button.position = button_pos
	
	print("spawned")


func despawn_interactive_button():
	if interactive_button and interactive_button.get_parent():
		interactive_button.queue_free()  # Remove button safely
		interactive_button = null  # Clear reference
		print("despawned")
		

func load_furnace_data():
	fuel_slot.set_item(self.fuel_slot_item)
	fuel_slot.set_count(self.fuel_slot_item_count)
		
	mats_slot.set_item(self.mats_slot_item)
	mats_slot.set_count(self.mats_slot_item_count)
		
	final_slot.set_item(self.final_slot_item)
	final_slot.set_count(self.final_slot_item_count)
		
	# Optionally, you can call update_display() to make sure everything is visually correct
	fuel_slot.update_display()
	mats_slot.update_display()
	final_slot.update_display()
	
func claim_furnace_item(slot):
	if slot == fuel_slot:
		self.fuel_slot_item = null
		self.fuel_slot_item_count = 0
	elif slot == mats_slot:
		self.mats_slot_item = null
		self.mats_slot_item_count = 0
	elif slot == final_slot:
		self.final_slot_item = null
		self.final_slot_item_count = 0
	
	print("✅ Item claimed from furnace:", slot)


# Setters for furnace slot items and their counts

func set_fuel_slot_item(item, item_count) -> void:
	self.fuel_slot_item =item
	self.fuel_slot_item_count = item_count

func set_mats_slot_item(item, item_count) -> void:
	self.mats_slot_item = item
	self.mats_slot_item_count = item_count

func set_final_slot_item(item, item_count) -> void:
	self.final_slot_item = item
	self.final_slot_item_count = item_count
	
var accepted_fuel = ["WOODEN_LOG"]
var accepted_for_smelting = ["BLOCK_IRON"]

var smelt_timer = Timer.new()

func smelt_item(fuel, raw_ore, fuel_count, raw_ore_count):
	
	if fuel_slot_item_count <= 0:
		set_fuel_slot_item(null, 0)
		load_furnace_data()
		return
	
	if mats_slot_item_count <= 0:
		set_mats_slot_item(null, 0)
		load_furnace_data()
	
	if smelt_timer:
		_parent_node.add_child(smelt_timer)
		smelt_timer.name = "SmeltTimer"
		smelt_timer.wait_time = 3  # Wait for 3 seconds (change as needed)
		smelt_timer.one_shot = true
	
	if fuel and fuel.get_name() in accepted_fuel:
		if raw_ore and raw_ore.get_name() in accepted_for_smelting:
			print("🔥 Smelting in progress...")
			smelt_timer.start()
			await smelt_timer.timeout  # Wait until timer finishes
			
			raw_ore = self.mats_slot_item
			if raw_ore and raw_ore.get_name() in accepted_for_smelting:
			
				# Smelting is complete
				set_fuel_slot_item(fuel_slot_item, fuel_slot_item_count - 1)
				set_mats_slot_item(mats_slot_item, mats_slot_item_count - 1)
					
				
				set_final_slot_item(dl.create_item("IRON"), final_slot_item_count + 1)
				load_furnace_data()
					
				print("✅ Smelting Complete")
				
				smelt_item(fuel, raw_ore, fuel_count, raw_ore_count)

				
			
