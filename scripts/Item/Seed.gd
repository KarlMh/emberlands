class_name Seed
extends Item

func _init(id: int, name: String, crafting_tier: int, icon: Texture2D):
	super._init(id, name, crafting_tier, icon, ItemType.SEED)

func can_be_placed() -> bool:
	return true  # Seeds can be placed
