extends ParallaxBackground

@export var scroll_speed: float = 3.0  # Base scroll speed
var clouds_layer: ParallaxLayer
var clouds2_layer: ParallaxLayer
var original_offset_x: float
var original_offset_x2: float

func _ready():
	# Get all ParallaxLayer nodes
	var layers = get_children()

	# Ensure we have at least three layers to avoid errors
	if layers.size() > 2:
		clouds_layer = layers[2]  # Assuming clouds are the third layer
		clouds2_layer = layers[1] # Assuming clouds2 is the second layer
		original_offset_x = clouds_layer.motion_offset.x
		original_offset_x2 = clouds2_layer.motion_offset.x

func _process(delta):
	if clouds_layer and clouds2_layer:
		# Move both cloud layers using motion_offset
		clouds_layer.motion_offset.x -= scroll_speed * delta
		clouds2_layer.motion_offset.x -= (scroll_speed * 3) * delta  # Adjust speed for parallax effect

		# Reset offsets when they move too far
		if clouds_layer.motion_offset.x < original_offset_x - 1000:
			clouds_layer.motion_offset.x = original_offset_x

		if clouds2_layer.motion_offset.x < original_offset_x2 - 1000:
			clouds2_layer.motion_offset.x = original_offset_x2
