extends Control

# Variables for inventory window
var is_inventory_open = false
@onready var inventory_window = self

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
	is_inventory_open = !is_inventory_open
	inventory_window.visible = is_inventory_open

	# Reset the inventory window's position when opened
	if is_inventory_open:
		update_limits()


func _process(delta):
	if not is_dragging and velocity.length() > 0.1:  # Apply momentum only if there's enough velocity
		velocity *= friction  # Apply friction for smooth slowdown
		inventory_window.global_position += velocity  # Move the inventory window

		# Ensure it never moves outside the screen (stay within bounds)
		inventory_window.global_position = inventory_window.global_position.clamp(min_pos, max_pos)

		# Stop movement when it's almost still
		if velocity.length() < 0.1:
			velocity = Vector2.ZERO
