extends Button

@onready var ChatBox = get_tree().get_root().find_child("ChatBox", true, false)

var dragging = false
var last_mouse_position = Vector2.ZERO
var is_open = false
var total_drag_distance = 0  # Track total movement

const MIN_Y = -400
const MAX_Y = -5
const CLICK_THRESHOLD = 5  # Max movement to still count as a click

func _on_button_down() -> void:
	dragging = true
	last_mouse_position = get_global_mouse_position()
	total_drag_distance = 0  # Reset drag distance

func _on_button_up() -> void:
	dragging = false
	
	# If the drag distance was small, treat it as a click
	if total_drag_distance < CLICK_THRESHOLD:
		toggle_chat_panel()

func _gui_input(event):
	if dragging and event is InputEventMouseMotion:
		var mouse_position = get_global_mouse_position()
		var delta = mouse_position - last_mouse_position

		# Move only vertically and clamp within limits
		ChatBox.position.y = clamp(ChatBox.position.y + delta.y, MIN_Y, MAX_Y)

		# Track total drag distance
		total_drag_distance += abs(delta.y)
		last_mouse_position = mouse_position

func toggle_chat_panel():
	if is_open:
		ChatBox.position.y = MAX_Y  # Close the panel
	else:
		ChatBox.position.y = MIN_Y  # Open the panel
	
	is_open = !is_open  # Toggle state
