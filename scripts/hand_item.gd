extends Node2D

@onready var hand_sprite = $"."  # Sprite to display equipped item
@onready var player_id = multiplayer.get_unique_id()
@onready var player = get_tree().get_root().find_child("Player_" + str(player_id), true, false)

var equipped_item: Item = null

# Equip a hand item (Pickaxe, Sword, etc.)
func equip_item(item: Item):
	if item == null or !item is Tool:  # Ensure it's a hand item
		return

	equipped_item = item
	hand_sprite.texture = item.get_icon()  # Update displayed texture
	apply_item_effects()

	# Adjust the pivot offset and position the sprite on the handle
	adjust_sprite_position(item)

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

	if equipped_item is Tool:
		player.mining_power += equipped_item.tool_power  # Boost mining power
		print("Mining Power increased by:", equipped_item.tool_power)

# Remove tool effects when unequipped
func remove_item_effects():
	if equipped_item == null:
		return

	if equipped_item is Tool:
		player.mining_power -= equipped_item.tool_power  # Reset power boost
		print("Mining Power reset")

# Handle switching between tools (e.g., from UI)
func switch_item(new_item: Item):
	if equipped_item == new_item:
		unequip_item()
	else:
		equip_item(new_item)

# Adjust sprite pivot and position it correctly based on the tool's handle
func adjust_sprite_position(item: Item):
	if equipped_item == null:
		return

	# Example: Tool handle's position offset (Adjust these values based on your tool's design)
	var pivot_offset = Vector2.ZERO  # Default pivot is the center of the sprite

	# Adjust the pivot_offset based on the tool type (you can modify this for different items)
	if item.get_name() == "GOLDEN_PICKAXE" or item.get_name() == "WOODEN_PICKAXE":
		# Position the sprite on the handle (example offset)
		pivot_offset = Vector2(5, 0)  # Adjust based on where the handle of the pickaxe is
	

	# Set the pivot offset for the hand sprite (this moves the "center" of the sprite)
	hand_sprite.offset = pivot_offset
