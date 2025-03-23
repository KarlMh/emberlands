extends Control

@onready var icon: TextureRect = $'icon'
@onready var label: Label = $'icon/Label'
var item_count: int = 0
var item: Item = null
var hand_item_slot: Control  # Reference to the hand item slot
var hand_item: Node2D
var inventory
var inventory_bar
var smelt_slot_container
var player

var dl = DataLoader

var can_drag_and_drop: bool = true  # Set to false for slots that should not support drag & drop

@onready var SmeltingPanel = get_tree().get_root().find_child("SmeltingPanel", true, false)

func _ready():
	# Find references to key UI elements
	hand_item_slot = get_tree().get_root().find_child("hand_slot", true, false)
	hand_item = get_tree().get_root().find_child("hand_item", true, false)
	inventory = get_tree().get_root().find_child("slot_container", true, false)
	inventory_bar = get_tree().get_root().find_child("slot_bar", true, false)
	smelt_slot_container = get_tree().get_root().find_child("smelt_slot_container", true, false)
	player = get_tree().get_root().find_child("player", true, false)
	is_dragable()

func set_item(new_item: Item) -> void:
	item = new_item
	if item:
	
		icon.texture = item.item_icon  # Use full texture for other items
		
		update_display()
	else:
		icon.texture = null  # Reset texture

func set_count(count: int):
	if item:
		item_count = count
	update_display()
	
func remove_item(count):
	if item:
		item_count -= count
		
		if item_count <= 0:
			clear_slot()

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
			return
		
		# Find furnace slots
		var block = SmeltingPanel.furnace_in_use
		
		if item and self in smelt_slot_container.smelting_slots:	
			var resource_type = dl._get(item.get_name())
			if resource_type:
				resource_type = resource_type["resource_type"]

			
			# Auto-add to the correct slot
			if resource_type == "fuel":
				if not block.fuel_slot_item:
					block.set_fuel_slot_item(item, item_count)

					block.load_furnace_data()
					inventory.remove_item(item, item_count)
					
			elif resource_type == "raw_ore":
				if not block.mats_slot_item:
					block.set_mats_slot_item(item, item_count)
		
					block.load_furnace_data()
					inventory.remove_item(item, item_count)
				
			block.smelt_item(block.fuel_slot_item, block.mats_slot_item, block.fuel_slot_item_count, block.mats_slot_item_count)
			smelt_slot_container.sync_with_inventory()
			
		if item and SmeltingPanel.visible: 
			if self in block.furnace_slots :
				block.claim_furnace_item(self)
				for i in item_count:
					inventory.add_item(item)
				block.load_furnace_data()
				
		smelt_slot_container.sync_with_inventory()

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


### 🟢 DRAG & DROP IMPLEMENTATION ###
var allowed_to_dnd = ["fuel_slot", "mats_slot", "final_slot", "smelting_slot"]

func is_dragable():
	print(self.name)

	# Check if self.name is in the list or contains any of the allowed slot names
	for slot_name in allowed_to_dnd:
		if self.name.begins_with(slot_name):
			can_drag_and_drop = true
			return  # Exit early if a match is found

	can_drag_and_drop = false  # Default to false if no match found


func _get_drag_data(position):
	is_dragable()
	if not item or not can_drag_and_drop:
		return null  # Don't allow dragging
	
	# Create a preview of the item
	var drag_preview = TextureRect.new()
	drag_preview.texture = icon.texture
	drag_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	drag_preview.size = Vector2(64, 64)  # Adjust preview size
	drag_preview.modulate = Color(1, 1, 1, 0.7)  # Make semi-transparent
	drag_preview.z_index = 100
	
	set_drag_preview(drag_preview)  # Show preview above UI
	
	# Return item data so it can be dropped somewhere else
	return {"item": item, "count": item_count, "origin_slot": self}

func _can_drop_data(position, data):
	return can_drag_and_drop and data is Dictionary and "item" in data  # Allow only if enabled

func _drop_data(position, data):
	if not can_drag_and_drop or not data or not data.has("item"):
		return  # Invalid drop or slot not allowed
	
	var block = SmeltingPanel.furnace_in_use

	var dropped_item = data["item"]
	var dropped_count = data["count"]
	var origin_slot = data["origin_slot"]

	if origin_slot == self:
		return  # Dropping onto itself, do nothing

	# 🔥 CASE 1: Smelting Slot (Sync with Inventory)
	if self.name.begins_with("smelting_slot") and (origin_slot.name.begins_with("fuel_slot") or origin_slot.name.begins_with("mats_slot") or origin_slot.name.begins_with("final_slot")):
		move_item_to_inventory(origin_slot, self, dropped_item, dropped_count)

	# 🔥 CASE 2: Furnace Slots (fuel, material, final)
	elif self.name.begins_with("fuel_slot") or self.name.begins_with("mats_slot") or self.name.begins_with("final_slot"):
		move_item_to_furnace(origin_slot, self, dropped_item, dropped_count)
		if !origin_slot.name.begins_with("smelting_slot"):
			block.claim_furnace_item(origin_slot)
			
	elif self.name == "hand_slot" and dropped_item is Tool:
		origin_slot.move_to_hand()  # Call the move_to_hand function to equip the tool
		
	smelt_slot_container.sync_with_inventory()
	
func move_item_to_furnace(origin_slot, furnace_slot, item, count):
	if not origin_slot or not furnace_slot:
		return  # Invalid slots
	
	if furnace_slot.item:
		for i in furnace_slot.item_count:
			inventory.add_item(furnace_slot.item)  # Add the item back to the inventory

	furnace_slot.set_item(item)
	furnace_slot.set_count(count)
	origin_slot.clear_slot()
	
	var block = SmeltingPanel.furnace_in_use
	
	if furnace_slot.name.begins_with("fuel_slot"):
		block.set_fuel_slot_item()
	elif furnace_slot.name.begins_with("mats_slot"):
		block.set_mats_slot_item()
	elif furnace_slot.name.begins_with("final_slot"):
		block.set_final_slot_item()
		
		
	inventory.remove_item(item, count)
	
	block.smelt_item()
	
	

	
	
func move_item_to_inventory(furnace_slot, target_inventory_slot, item, count):
	if not furnace_slot or not target_inventory_slot:
		return  # Invalid slots
		
	if target_inventory_slot.item:
		target_inventory_slot.set_item(item)
		target_inventory_slot.set_count(count)
	
	var block = SmeltingPanel.furnace_in_use


	block.claim_furnace_item(furnace_slot)
	furnace_slot.clear_slot()
	
	for i in count:
		inventory.add_item(item)  # Add the item back to the inventory
	
	block.smelt_item()
	
	
func update_smelt_slot_display():
	# Loop through all smelting slots and update their display
	var smelting_slots = smelt_slot_container.get_children()
	for slot in smelting_slots:
		slot.update_display()  # Ensure each slot display is updated properly
