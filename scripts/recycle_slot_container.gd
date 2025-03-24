extends GridContainer

@onready var inventory_manager = get_tree().get_root().find_child("slot_container", true, false)
@onready var inventory_slot_scene = load("res://scenes/inventory_slot.tscn")

var recycle_slots: Array = []  # Stores smelting inventory slots
const MAX_RECYCLE_SLOTS = 20  # Number of smelting slots

func _ready():
	if not inventory_manager:
		print("Error: Could not find inventory_manager!")
		return

	initialize_recycling_slots()
	sync_with_inventory()

# 🔹 Create Empty Smelting Slots
func initialize_recycling_slots():
	for i in range(MAX_RECYCLE_SLOTS):
		var slot_instance = inventory_slot_scene.instantiate()
		add_child(slot_instance)
		recycle_slots.append(slot_instance)
		slot_instance.name = "recycling_slot_%d" % i
		slot_instance.update_display()

		# Enable drag & drop for smelting slots
		slot_instance.can_drag_and_drop = true

# 🔹 Sync Smelting Inventory with Main Inventory (Clears & Reorders)
func sync_with_inventory():
	# Clear all smelting slots before reassigning
	for recycle_slot in recycle_slots:
		recycle_slot.clear_slot()
	
	# Fetch resource items from inventory_manager
	var resource_slots = inventory_manager.get_children().filter(func(slot): return slot.item)

	# Sort the resource slots by item count (optional, for better stacking)
	resource_slots.sort_custom(func(a, b): return a.item_count > b.item_count)
	
	if len(resource_slots) == 0:
		print("no SLOT ITEM IN RECYCLER!")
	
	for i in resource_slots:
		print(i.get_name())

	# Assign inventory slots to smelting slots without empty gaps
	for i in range(min(len(resource_slots), MAX_RECYCLE_SLOTS)):
		var inv_slot = resource_slots[i]
		var recycle_slot = recycle_slots[i]
		
		# Assign new item from inventory
		recycle_slot.set_item(inv_slot.item)
		recycle_slot.set_count(inv_slot.item_count)
		recycle_slot.update_display()

	print("Recycling inventory synced and reorganized!")
