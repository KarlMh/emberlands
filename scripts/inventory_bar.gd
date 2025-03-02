extends Control

@export var bar_container: Container  # Parent of all inventory bar slots
@export var inventory: Node  # Reference to the inventory system

var fixed_slots: Array = []  # First 2 slots (Hand & Tool)
var dynamic_slots: Array = []  # Last 3 slots (dynamic inventory)
var selected_slot_index: int = 0  # Currently selected slot index

@onready var dl = DataLoader

func _ready():
	inventory = get_tree().get_root().find_child("slot_container", true, false)
	# Initialize inventory bar slots
	for i in range(bar_container.get_child_count()):
		var child = bar_container.get_child(i)
		if child is Control:
			if i < 2:
				fixed_slots.append(child)  # First 2 slots go to fixed_slots
			else:
				dynamic_slots.append(child)  # Last 3 slots go to dynamic_slots
			child.connect("gui_input", Callable(self, "_on_slot_gui_input").bind(child, i))

	# Assign fixed items
	if fixed_slots.size() >= 2:
		var hand_item = Item.new(-10, "Hand", -1, preload("res://pixel_art/items/PLAYER_HAND.png"), 0)


		await get_tree().process_frame  # Wait for UI to be ready

		print("BOOOBBAA")

		fixed_slots[0].set_item(hand_item)
		fixed_slots[0].item_count = 1
		fixed_slots[0].update_display()

	# Set the initial selected slot (default to first slot)
	selected_slot_index = 0
	update_selection_visual()

# Handle input events (mouse selection)
func _on_slot_gui_input(event: InputEvent, slot: Control, index: int):
	if event is InputEventMouseButton and event.pressed:
		selected_slot_index = index
		update_selection_visual()
		inventory.selected_slot = slot

# Handle keyboard input (1-5 for selection)
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var index = event.keycode - KEY_1
			if index < fixed_slots.size() + dynamic_slots.size():
				selected_slot_index = index
				update_selection_visual()
				if index < fixed_slots.size():
					inventory.selected_slot = fixed_slots[index]
				else:
					inventory.selected_slot = dynamic_slots[index - fixed_slots.size()]

# Update the visual appearance of the selected slot
func update_selection_visual():
	for i in range(fixed_slots.size()):
		fixed_slots[i].modulate = Color(1, 1, 1, 1) if i == selected_slot_index else Color(0.8, 0.8, 0.8, 1)

	for i in range(dynamic_slots.size()):
		var slot_index = i + fixed_slots.size()
		dynamic_slots[i].modulate = Color(1, 1, 1, 1) if slot_index == selected_slot_index else Color(0.8, 0.8, 0.8, 1)

# Add an item to the dynamic inventory (last three slots only)
func add_to_bar(slot: Control):
	if not slot or not slot.item or slot.item.is_tool():
		return

	# Check if item is already in dynamic slots
	for i in range(dynamic_slots.size()):
		if dynamic_slots[i].item and dynamic_slots[i].item.item_id == slot.item.item_id:
			dynamic_slots[i].item_count += slot.item_count  # Update count
			dynamic_slots[i].update_display()
			return

	# If dynamic slots are full, shift items
	if dynamic_slots[2].item:  # Last slot occupied? Remove oldest
		dynamic_slots[0].clear_slot()
		for i in range(2):
			dynamic_slots[i].set_item(dynamic_slots[i + 1].item)
			dynamic_slots[i].item_count = dynamic_slots[i + 1].item_count
			dynamic_slots[i].update_display()
		dynamic_slots[2].clear_slot()

	# Find an empty slot in dynamic slots and place new item
	for i in range(dynamic_slots.size()):
		if not dynamic_slots[i].item:
			dynamic_slots[i].set_item(slot.item)
			dynamic_slots[i].item_count = slot.item_count
			dynamic_slots[i].update_display()
			return

# Update the inventory bar display when inventory changes
func update_bar_display():
	# Update dynamic slots
	for bar_slot in dynamic_slots:
		if bar_slot.item:
			var found = false
			for inv_slot in inventory.slots:
				if inv_slot.item and inv_slot.item.item_id == bar_slot.item.item_id:
					bar_slot.item_count = inv_slot.item_count
					bar_slot.update_display()
					found = true
					break
			if not found or bar_slot.item_count <= 0:
				bar_slot.clear_slot()

# Check if the dynamic inventory is full
func is_bar_full() -> bool:
	for slot in dynamic_slots:
		if not slot.item:
			return false
	return true
