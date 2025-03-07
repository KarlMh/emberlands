class_name Background
extends Item

var item_gems: int

func _init(id: int, name: String, crafting_tier: int, icon: Texture2D, gems: int):
	super._init(id, name, crafting_tier, icon, ItemType.BACKGROUND)
	self.item_gems = gems

func can_be_placed() -> bool:
	return true  # Background blocks can be placed
