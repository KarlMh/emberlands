extends Button

@onready var main_inventory = get_tree().get_root().find_child("main_inventory", true, false)
@onready var crafting_inventory = get_tree().get_root().find_child("crafting_inventory", true, false)

func _on_pressed() -> void:
	# Toggle visibility correctly
	var craft_is_visible = crafting_inventory.visible
	crafting_inventory.visible = !craft_is_visible
	main_inventory.visible = craft_is_visible
