extends Item
class_name Tool


var tool_power: float

func _init(id: int, name: String, crafting_tier: int, icon: Texture2D, power: float):
	super._init(id, name, crafting_tier, icon, ItemType.TOOL)
	self.tool_power = power
