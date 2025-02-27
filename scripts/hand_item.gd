extends Node2D

@onready var hand_sprite = $"."  # Sprite to display equipped item
@onready var player = $"../../../.."  # Reference to the player node

var equipped_item: Item = null

# Equip a hand item (Pickaxe, Sword, etc.)
func equip_item(item: Item):
	if item == null or !item.is_tool():  # Ensure it's a hand item
		return

	equipped_item = item
	hand_sprite.texture = item.get_icon()  # Update displayed texture
	apply_item_effects()

	print("Equipped:", item.item_name)

func unequip_item():
	remove_item_effects()
	equipped_item = null
	hand_sprite.texture = null  # Ensure texture is removed

	print("Unequipped item")


# Apply the tool's effect (Extra power, faster mining, etc.)
func apply_item_effects():
	if equipped_item == null:
		return

	if equipped_item.is_tool():
		player.mining_power += equipped_item.tool_power  # Boost mining power
		print("Mining Power increased by:", equipped_item.tool_power)

# Remove tool effects when unequipped
func remove_item_effects():
	if equipped_item == null:
		return

	if equipped_item.is_tool():
		player.mining_power -= equipped_item.tool_power  # Reset power boost
		print("Mining Power reset")

# Handle switching between tools (e.g., from UI)
func switch_item(new_item: Item):
	if equipped_item == new_item:
		unequip_item()
	else:
		equip_item(new_item)
