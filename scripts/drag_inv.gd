extends Control

var is_inventory_open = false
var inventory_window : Control

var is_dragging = false
var drag_offset = Vector2()
var min_y
var max_y

var velocity = 0.0
var friction = 0.85

func _ready():
	print("Inventory UI is ready!")  # Debugging
	set_process_input(true)  # Ensure _input() runs
	process_mode = Node.PROCESS_MODE_ALWAYS  # Force input even if paused
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Prevent UI from blocking input


func update_limits():
	var screen_height = get_viewport_rect().size.y
	min_y = screen_height * 0.5
	max_y = screen_height * 0.9
	inventory_window.position.y = clamp(inventory_window.position.y, min_y, max_y)

func _input(event):
	print("Input detected:", event)  # Debugging

	if event.is_action_pressed("ui_inventory"):
		print("E key pressed - toggling inventory")


func toggle_inventory():
	is_inventory_open = !is_inventory_open
	inventory_window.visible = is_inventory_open
	if is_inventory_open:
		inventory_window.position = Vector2(get_viewport_rect().size.x / 2 - inventory_window.size.x / 2, min_y)

func _on_inventory_window_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - inventory_window.global_position
			velocity = 0
		else:
			is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		var target_position = get_global_mouse_position() - drag_offset
		target_position.y = clamp(target_position.y, min_y - 20, max_y + 20)
		velocity = target_position.y - inventory_window.global_position.y
		inventory_window.global_position.y = lerp(inventory_window.global_position.y, target_position.y, 0.4)

func _process(delta):
	if not is_dragging and abs(velocity) > 0.1:
		velocity *= friction
		inventory_window.global_position.y += velocity

		if inventory_window.global_position.y < min_y:
			inventory_window.global_position.y = min_y
			velocity = 0
		elif inventory_window.global_position.y > max_y:
			inventory_window.global_position.y = max_y
			velocity = 0
