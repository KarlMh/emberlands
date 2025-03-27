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
@onready var RecyclingPanel = get_tree().get_root().find_child("RecyclingPanel", true, false)
@onready var recycle_slot_container = get_tree().get_root().find_child("recycle_slot_container", true, false)
@onready var count_item_recycle = get_tree().get_root().find_child("count_item_recycle", true, false)
@onready var count_item_smelt = get_tree().get_root().find_child("count_item_smelt", true, false)



func _ready():
	# Find references to key UI elements
	hand_item_slot = get_tree().get_root().find_child("hand_slot", true, false)
	hand_item = get_tree().get_root().find_child("hand_item", true, false)
	inventory = get_tree().get_root().find_child("slot_container", true, false)
	inventory_bar = get_tree().get_root().find_child("slot_bar", true, false)
	smelt_slot_container = get_tree().get_root().find_child("smelt_slot_container", true, false)
	player = get_tree().get_root().find_child("player", true, false)

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
	
func get_item():
	return item
	
func get_count():
	return item_count
	
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
		
		
func recycle():
	var recycler = RecyclingPanel.recycler_in_use
			
	var input_text = count_item_recycle.count

	# Try to convert the input to an integer
	var temp_item_count = int(input_text) 
			
	if temp_item_count <= item_count:
		# Set recycler data with the item and item_count from user input
		recycler.set_recycler_data(item, temp_item_count, false)
						
		# Remove the item from the inventory
		inventory.remove_item(item, temp_item_count)
		recycler.load_recycler_data()
					
		# Recycle the item with the specified count	
		recycler.recycle_item(item, temp_item_count, self)
		recycler.load_recycler_data()
		recycle_slot_container.sync_with_inventory()
		
func smelt():
	var block = SmeltingPanel.furnace_in_use
	var input_text = count_item_smelt.count  # Get user input count
	var temp_item_count = int(input_text)  # Convert input to integer
	
	if temp_item_count <= item_count:
		var resource_type = dl._get(item.get_name())
		if resource_type:
			resource_type = resource_type["resource_type"]

		# Auto-add to the correct slot with input count
		if resource_type == "fuel":
			block.set_fuel_slot_item(item, temp_item_count)
			block.load_furnace_data()
			inventory.remove_item(item, temp_item_count)
				
		elif resource_type == "raw_ore":
			block.set_mats_slot_item(item, temp_item_count)
			block.load_furnace_data()
			inventory.remove_item(item, temp_item_count)

		block.smelt_item(
			block.fuel_slot_item, 
			block.mats_slot_item, 
			block.fuel_slot_item_count, 
			block.mats_slot_item_count
		)
		smelt_slot_container.sync_with_inventory()


func _gui_input(event):
	if event is InputEventMouseButton and event.double_click:
		if hand_item_slot.get_global_rect().has_point(event.position):
			return
		if item and (self in inventory.slots or self == hand_item_slot) and item.item_type == Item.ItemType.TOOL:
			move_to_hand()
			return

		if item and self in recycle_slot_container.recycle_slots:
			count_item_recycle.last_slot = self
			count_item_recycle.visible = true
			
		var recycler = RecyclingPanel.recycler_in_use
		
		if item and recycler and (self in recycler.upper_slots.get_children() or self in recycler.down_slots.get_children()):
			for i in item_count:
				inventory.add_item(item)
				
			recycler.claim_recycler_item(self)
			
		
		recycle_slot_container.sync_with_inventory()
		
		# Find furnace slots
		
		if item and self in smelt_slot_container.smelting_slots:
			count_item_smelt.last_slot = self
			count_item_smelt.visible = true
			
		var block = SmeltingPanel.furnace_in_use
		
		
			
		if item and SmeltingPanel.visible: 
			if self in block.furnace_slots :
				block.claim_furnace_item(self)
				for i in item_count:
					inventory.add_item(item)
				block.load_furnace_data()
				
		smelt_slot_container.sync_with_inventory()
		update_smelt_slot_display()

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



	
	
func update_smelt_slot_display():
	# Loop through all smelting slots and update their display
	var smelting_slots = smelt_slot_container.get_children()
	for slot in smelting_slots:
		slot.update_display()  # Ensure each slot display is updated properly
		
		
func _on_mouse_entered() -> void:
	player.can_build = false


func _on_mouse_exited() -> void:
	player.can_build = true
