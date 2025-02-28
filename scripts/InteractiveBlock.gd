extends Block
class_name InteractiveBlock

# New properties specific to interactive blocks
var _interaction_type: String = ""

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
