extends Control

var inventory_bar: Node  # Reference to the inventory bar system

var slots: Array = []  # Holds all inventory slots
var selected_slot: Control = null  # Track the currently selected slot
var hand_slot

func _ready():
	inventory_bar = get_tree().get_root().find_child("slot_bar", true, false)
	hand_slot = get_tree().get_root().find_child("hand_slot", true, false)
	# Initialize inventory slots
	for child in self.get_children():
		if child is Control:  # Ensure it's an inventory slot
			slots.append(child)
			child.connect("gui_input", Callable(self, "_on_slot_gui_input").bind(child))

# Handle input events on slots
func _on_slot_gui_input(event: InputEvent, slot: Control):
	if event is InputEventMouseButton and event.pressed:
		if selected_slot != slot:  # Only update if a new slot is selected
			selected_slot = slot
			add_selected_to_bar()  # Add to bar immediately
			
# Get the currently selected item
func get_selected_item() -> Item:
	if selected_slot and selected_slot.item and selected_slot.item_count > 0:
		return selected_slot.item
	return null

# Only sorts when an item is added or removed, not every frame
var sort_pending = false  # Track when sorting is needed

func add_item(item: Item) -> void:
	# First, add the item to the inventory
	for slot in slots:
		if slot.item and slot.item.item_id == item.item_id:
			slot.item_count += 1
			slot.set_item(slot.item)
			slot.update_display()
			inventory_bar.update_bar_display()
			sort_pending = true  # Mark sorting needed
			return

	for slot in slots:
		if not slot.item:
			slot.set_item(item)
			slot.item_count = 1
			slot.update_display()

			if not inventory_bar.is_bar_full():
				inventory_bar.add_to_bar(slot)
			inventory_bar.update_bar_display()
			sort_pending = true  # Mark sorting needed
			return

	print("Inventory is full!")

func remove_item(item: Item, count: int = 1) -> void:
	for slot in slots:
		if slot.item and slot.item.item_id == item.item_id:
			slot.item_count -= count
			
			if slot.item_count <= 0:
				slot.clear_slot()
				sort_pending = true  # Mark sorting needed
			else:
				slot.set_item(slot.item)

			slot.update_display()
			inventory_bar.update_bar_display()
			return

	print("Error: Item not found in inventory!")
	
func get_item_count(item_name: String) -> int:
	for slot in slots:
		if slot.item:
			if slot.item.get_name() == item_name:
				return slot.item_count
	return 0

func get_item_by_name(item_name: String) -> Item:
	for slot in slots:
		if slot.item and slot.item.item_name == item_name:
			return slot.item
	return null


# Instead of running sort_inventory() every frame, do it when needed
func _process(delta: float) -> void:
	if sort_pending:
		sort_inventory()
		sort_pending = false  # Reset flag


func sort_inventory():
	var sorted_slots := []  

	# 1️⃣ Collect non-empty slots **before clearing**
	var inventory_info = ""  # String to collect all item info for later display
	for slot in slots:
		if slot.item:
			sorted_slots.append({
				"item": slot.item,
				"item_count": slot.item_count
			})
			# Collect item info for display later
			inventory_info += slot.item.item_name + " (Count: " + str(slot.item_count) + "), "

	# Remove the trailing comma and space
	if inventory_info.length() > 0:
		print(inventory_info)

	# 2️⃣ Sort items by ID **to ensure correct order**
	sorted_slots.sort_custom(func(a, b):
		return a["item"].item_id < b["item"].item_id
	)

	# 3️⃣ Clear inventory slots **before refilling**
	for slot in slots:
		slot.clear_slot()

	# 4️⃣ Refill slots with sorted items
	for i in range(sorted_slots.size()):
		var slot_data = sorted_slots[i]
		slots[i].set_item(slot_data["item"])
		slots[i].item_count = slot_data["item_count"]
		slots[i].update_display()

	# 5️⃣ Ensure UI updates properly
	inventory_bar.update_bar_display()

	print("Inventory sorted successfully.")





# Add the selected item to the inventory bar immediately
func add_selected_to_bar():
	if selected_slot and selected_slot.item:
		inventory_bar.add_to_bar(selected_slot)
		inventory_bar.update_bar_display()  # Ensure bar updates immediately
