extends Camera2D

@export var zoom_speed: float = 0.2  # How fast to zoom
@export var min_zoom: float = 2.5    # Minimum zoom level
@export var max_zoom: float = 6.0    # Maximum zoom level

@onready var player = $"../player"  # Adjust if necessary
@onready var blockLayer = $"../blockLayer"  # Adjust to match your world blockLayer

var inventory_window

var world_width = 100  # Must match world generation size
var world_height = 50  # Set according to your world size
var tile_size = 32  # Tile size in pixels

func _ready():
	make_current()  # Set this camera as the active camera
	position = player.position  # Start at player's position
	inventory_window = get_tree().get_root().find_child("inventory_window", true, false)

func _process(delta):
	if not player:
		return  # Prevent errors if player is missing

	# Get screen half-width to calculate boundaries dynamically
	var half_screen_width = (get_viewport_rect().size.x / 2) / zoom.x

	# Reduce the boundaries by 1 tile to hide empty bedrock
	var max_x = ((world_width - 1) * tile_size) - half_screen_width
	var min_x = (1 * tile_size) + half_screen_width  # Start at 1 tile instead of 0

	# Clamp the camera to prevent viewing beyond bedrock
	var target_x = clamp(player.position.x, min_x, max_x)
	position.x = target_x

	# Follow Y position normally
	position.y = player.position.y

func _input(event):
	if event is InputEventMouseButton:
		# Check if the inventory window is visible and the mouse is over it
		if inventory_window and inventory_window.visible:
			var mouse_pos = get_viewport().get_mouse_position()
			var inv_rect = inventory_window.get_global_rect()

			# If the mouse is inside the inventory window, ignore zoom input
			if inv_rect.has_point(mouse_pos):
				return

		# Apply zoom if mouse is NOT over the inventory window
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom -= Vector2(zoom_speed, zoom_speed)  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += Vector2(zoom_speed, zoom_speed)  # Zoom out

		# Clamp zoom to stay within limits
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
