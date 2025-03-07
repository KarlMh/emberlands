extends Item
class_name Resources

func _init(id: int, name: String, crafting_tier: int, icon: Texture2D):
	super._init(id, name, crafting_tier, icon, ItemType.RESOURCE)
