# 📜 Base Item Class
class_name Item
extends Object

enum ItemType { BLOCK, INTERACTIVE_BLOCK, BACKGROUND, TOOL, SEED, RESOURCE }

var item_id: int
var item_name: String
var crafting_tier: int
var item_icon: Texture2D
var item_type: ItemType
var item_count: int

func _init(id: int, name: String, crafting_tier: int, icon: Texture2D, type: ItemType):
	self.item_id = id
	self.item_name = name
	self.crafting_tier = crafting_tier
	self.item_icon = icon
	self.item_type = type

func get_icon() -> Texture2D:
	return item_icon

func get_name() -> String:
	return item_name

func get_id() -> int:
	return item_id

func can_be_placed() -> bool:
	return false  # Default: Not placeable
