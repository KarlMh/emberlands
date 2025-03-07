extends Item
class_name Block

var item_gems: int  # Gems given for breaking

func _init(id: int, name: String, crafting_tier: int, icon: Texture2D, gems: int):
	super._init(id, name, crafting_tier, icon, ItemType.BLOCK)
	self.item_gems = gems

func can_be_placed() -> bool:
	return true  # Blocks can be placed
