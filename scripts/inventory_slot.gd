extends Control

@onready var icon: TextureRect = $'icon'
@onready var label: Label = $'icon/Label'
var item_count: int = 0
var item: Item = null
var hand_item_slot: Control  # Reference to the hand item slot
var hand_item: Node2D
var inventory
var inventory_bar

func _ready():
	# Find references to key UI elements
	hand_item_slot = get_tree().get_root().find_child("hand_slot", true, false)
	hand_item = get_tree().get_root().find_child("hand_item", true, false)
	inventory = get_tree().get_root().find_child("slot_container", true, false)
	inventory_bar = get_tree().get_root().find_child("slot_bar", true, false)

func set_item(new_item: Item) -> void:
	item = new_item
	if item:
	
		icon.texture = item.item_icon  # Use full texture for other items

		update_display()
	else:
		icon.texture = null  # Reset texture


func clear_slot() -> void:
	item = null
	item_count = 0
	icon.texture = null
	update_display()

func update_display():
	if item:
		label.text = str(item_count) if item_count > 1 else ""  # Hide count if 1
	else:
		label.text = ""

func _gui_input(event):
	if event is InputEventMouseButton and event.double_click:
		if hand_item_slot.get_global_rect().has_point(event.position):
			return
		if item and item.item_type == Item.ItemType.TOOL:
			move_to_hand()

func move_to_hand():
	if not item:
		return  # No item to equip

	if hand_item_slot.item:
		if hand_item_slot.item == item:
			# Unequip if the same item is clicked
			hand_item.unequip_item()
			inventory.add_item(item)  # Return item to inventory
			hand_item_slot.clear_slot()  # Clear hand slot
		else:
			# Switching to a new item
			var current_hand_item = hand_item_slot.item  # Store the currently equipped item
			hand_item.unequip_item()
			inventory.add_item(current_hand_item)  # Return the old item to inventory
			hand_item_slot.clear_slot()
			
			hand_item.equip_item(item)  # Switch equipped item
			hand_item_slot.set_item(item)  # Update hand slot
			inventory.remove_item(item, 1)  # Remove one instance of the new item from inventory

	else:
		# Equip a new item if the hand slot is empty
		hand_item.equip_item(item)
		hand_item_slot.set_item(item)
		inventory.remove_item(item, 1)  # Remove from inventory only if newly equipped


func update_inventory():
	# Find and clear the corresponding slot in inventory
	for slot in inventory.get_children():
		if slot.item and slot.item.item_id == item.item_id:
			slot.clear_slot()
			break  # Stop once the first match is cleared

	clear_slot()  # Also clear the clicked slot in the bar()
	update_display()
	inventory_bar.update_bar_display()

func get_item() -> Item:
	return item  # Returns the item stored in this slot
