extends Button

@onready var main_inventory = get_tree().get_root().find_child("main_inventory", true, false)
@onready var crafting_inventory = get_tree().get_root().find_child("crafting_inventory", true, false)

func _ready() -> void:
	self.text = "->"
	# Ensure only the main inventory is visible initially
	main_inventory.visible = true
	crafting_inventory.visible = false

func _on_pressed() -> void:
	var craft_is_visible = crafting_inventory.visible
	
	# Toggle visibility
	crafting_inventory.visible = !craft_is_visible
	main_inventory.visible = craft_is_visible
	
	# Update button text
	self.text = "<-" if crafting_inventory.visible else "->"
