class_name Item

enum ItemType { BLOCK, BACKGROUND_BLOCK, TOOL, SEED }

var item_id: int
var item_name: String
var item_icon: Texture2D
var item_type: ItemType

var item_gems: int = 0  # 💎 Gems for breaking blocks

# Tool Properties
var tool_power: float = 0  # Strength of the tool

func _init(id: int, name: String, icon: Texture2D, type: ItemType):
	self.item_id = id
	self.item_name = name
	self.item_icon = icon
	self.item_type = type

# 🏗️ **FOREGROUND BLOCK Constructor** (For solid blocks)
static func create_block(id: int, name: String, icon: Texture2D, gems: int) -> Item:
	var item = Item.new(id, name, icon, ItemType.BLOCK)
	item.item_gems = gems
	return item

# 🏗️ **BACKGROUND BLOCK Constructor** (For decorative/non-solid blocks)
static func create_background_block(id: int, name: String, icon: Texture2D, gems: int) -> Item:
	var item = Item.new(id, name, icon, ItemType.BACKGROUND_BLOCK)
	item.item_gems = gems
	return item

# 🏗️ **SEED Constructor**
static func create_seed(id: int, name: String, icon: Texture2D) -> Item:
	var item = Item.new(id, name, icon, ItemType.SEED)
	return item

# 🔨 **TOOL Constructor**
static func create_tool(id: int, name: String, icon: Texture2D, power: float) -> Item:
	var item = Item.new(id, name, icon, ItemType.TOOL)
	item.tool_power = power
	return item

# 📜 **Utility Methods**
func get_icon() -> Texture2D:
	return item_icon

func get_name() -> String:
	return item_name

func get_id() -> int:
	return item_id

func is_tool() -> bool:
	return item_type == ItemType.TOOL

func is_block() -> bool:
	return item_type == ItemType.BLOCK

func is_background() -> bool:
	return item_type == ItemType.BACKGROUND_BLOCK
