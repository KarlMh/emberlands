extends Camera2D

@export var world_width: int = 6400  # World width in pixels (200 * 32)
@export var world_height: int = 3200  # World height in pixels (100 * 32)
@export var zoom_speed: float = 0.2   # Speed of zoom (scroll sensitivity)

@onready var ChatBox = get_tree().get_root().find_child("ChatBox", true, false)  # Find chat input field

var target_zoom: float = 4   # Current zoom level
var target_position: Vector2  # Position the camera should move to

const min_zoom = 2
const max_zoom = 10

func _ready():
	# Set the camera's limit properties based on the world size
	limit_left = 32
	limit_right = world_width - 32
	limit_top = 32
	limit_bottom = 10000000
	
	zoom = Vector2(target_zoom, target_zoom)

func _input(event):
	if event is InputEventMouseButton:
		if ChatBox.scroll_on_chat == true:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Zoom in (closer to the world)
			target_zoom = clamp(target_zoom - 0.1, min_zoom, max_zoom)  # Zoom in more
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Zoom out (further from the world)
			target_zoom = clamp(target_zoom + 0.1, min_zoom, max_zoom)  # Zoom out less
			
	zoom = Vector2(target_zoom, target_zoom)
