extends BlockEntity
class_name InteractiveBlockEntity

# New properties specific to interactive blocks
var _interaction_type: String = ""
var interactive_button: Control = null  # Store reference to button

# Constructor
func _init(id: int, position: Vector2i, parent_node: Node, can_be_damaged: bool):
	super(id, position, parent_node, can_be_damaged)  # Call parent constructor
	
	# Set interaction type if this block is interactive
	if _is_interactive:
		set_interaction_type()

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
