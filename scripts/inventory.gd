extends Control

# Variables for inventory window
var is_inventory_open = false
@onready var inventory_window = self

@onready var options = get_tree().get_root().find_child("options", true, false)

@onready var main_inventory = get_tree().get_root().find_child("main_inventory", true, false)
@onready var crafting_inventory = get_tree().get_root().find_child("crafting_inventory", true, false)
@onready var SmeltingPanel = get_tree().get_root().find_child("SmeltingPanel", true, false)
@onready var RecyclingPanel = get_tree().get_root().find_child("RecyclingPanel", true, false)

@onready var craft_toggle = get_tree().get_root().find_child("craft_toggle", true, false)


# Variables for dragging
var is_dragging = false
var drag_offset = Vector2()
var min_pos
var max_pos

var velocity = Vector2.ZERO  # Used for smooth motion on release
var friction = 0.85  # Controls how quickly the panel slows down

func _ready():
	# Ensure the node processes input
	set_process_input(true)

	# Start with the inventory hidden
	inventory_window.visible = false
	main_inventory.visible = true
	crafting_inventory.visible = false

	# Update limits and size based on the current screen size
	update_limits()

	# Connect to the viewport's size change signal to update limits dynamically
	get_viewport().size_changed.connect(update_limits)

func update_limits():
	# Get the current screen size
	var screen_size = get_viewport_rect().size

	# Set the size of the inventory window relative to the screen size
	inventory_window.size = Vector2(500, 250)  # 40% width, 40% height

	# Set strict movement limits (ensuring it stays fully inside)
	min_pos = Vector2(0, 0)  # Top-left corner
	max_pos = Vector2(screen_size.x - inventory_window.size.x, screen_size.y - inventory_window.size.y)

	# Ensure the inventory window stays within limits when the screen size changes
	inventory_window.position = inventory_window.position.clamp(min_pos, max_pos)

	# Center the inventory window when opening
	if not is_inventory_open:
		inventory_window.position = (screen_size - inventory_window.size) / 2

func _input(event):
	# Check if the "E" key is pressed to toggle the inventory
	if event.is_action_pressed("ui_inventory"):  # Ensure "ui_inventory" is set in the Input Map
		toggle_inventory()
	
	

func toggle_inventory():
	crafting_inventory.visible = false
	main_inventory.visible = true
	craft_toggle.text = "<-" if crafting_inventory.visible else "->"
	is_inventory_open = !is_inventory_open
	inventory_window.visible = is_inventory_open

	
	# Reset the inventory window's position when opened
	if is_inventory_open:
		update_limits()
		
	options.visible = false
	SmeltingPanel.visible = false
	RecyclingPanel.visible = false
	
func toggle_inventory_craft():
	if crafting_inventory.visible == false:
		crafting_inventory.visible = true
	else:
		crafting_inventory.visible = false



func _process(delta):	
	if not is_dragging and velocity.length() > 0.1:  # Apply momentum only if there's enough velocity
		velocity *= friction  # Apply friction for smooth slowdown
		inventory_window.global_position += velocity  # Move the inventory window

		# Ensure it never moves outside the screen (stay within bounds)
		inventory_window.global_position = inventory_window.global_position.clamp(min_pos, max_pos)

		# Stop movement when it's almost still
		if velocity.length() < 0.1:
			velocity = Vector2.ZERO
