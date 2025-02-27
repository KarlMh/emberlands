extends CanvasLayer

# Store the initial screen size
var initial_screen_size: Vector2
@onready var inv = $inventory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the initial screen size
	initial_screen_size = get_viewport().get_visible_rect().size

	# Connect to the viewport's size_changed signal using Callable
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

	# Adjust initial scale
	adjust_children_scale()

# Called whenever the viewport size changes
func _on_viewport_size_changed() -> void:
	adjust_children_scale()

# Function to adjust the scale of the children
func adjust_children_scale() -> void:
	# Get the current screen size
	var current_screen_size = get_viewport().get_visible_rect().size * 1.2

	# Calculate the uniform scale factor based on the smaller axis (to maintain aspect ratio)
	var scale_factor = min(
		current_screen_size.x / initial_screen_size.x,
		current_screen_size.y / initial_screen_size.y
	)

	# Apply the uniform scale to all direct children
	for child in get_children():
		if child is Control or child is Node2D:  # Scale UI or 2D elements
			child.scale = Vector2(scale_factor, scale_factor)
