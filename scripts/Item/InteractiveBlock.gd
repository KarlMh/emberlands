class_name InteractiveBlock
extends Item

var item_gems: int
var interactive_type: String

func _init(id: int, name: String, crafting_tier: int, interactive_type: String, icon: Texture2D, gems: int):
	super._init(id, name, crafting_tier, icon, ItemType.INTERACTIVE_BLOCK)
	self.item_gems = gems
	self.interactive_type = interactive_type

func can_be_placed() -> bool:
	return true  # Interactive blocks can be placed
