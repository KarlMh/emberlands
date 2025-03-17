extends Button

@onready var main_inventory = get_tree().get_root().find_child("main_inventory", true, false)
@onready var crafting_inventory = get_tree().get_root().find_child("crafting_inventory", true, false)

var current_inventory = 0  # 0 = Main, 1 = Crafting, 2 = Smelting

func _ready() -> void:
	self.text = "->"
	_show_inventory(0)  # Show main inventory at start

func _on_pressed() -> void:
	current_inventory = (current_inventory + 1) % 2  # Cycle through inventories
	_show_inventory(current_inventory)

func _show_inventory(index: int) -> void:
	main_inventory.visible = index == 0
	crafting_inventory.visible = index == 1

	# Update button text based on next inventory
	match index:
		0: self.text = "->"  # Main → Crafting
		2: self.text = "<-"  # Smelting → Main
