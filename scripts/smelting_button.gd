extends Button

@onready var SmeltingPanel = get_tree().get_root().find_child("SmeltingPanel", true, false)
@onready var smelt_slot_container = get_tree().get_root().find_child("smelt_slot_container", true, false)
@onready var player = get_tree().get_root().find_child("player", true, false)
@onready var inventory_slot = get_tree().get_root().find_child("inventory_slot", true, false)
@onready var inventory_window = get_tree().get_root().find_child("inventory_window", true, false)
@onready var options = get_tree().get_root().find_child("options", true, false)

var block_reference = null

func _on_pressed() -> void:
	if inventory_window.visible or options.visible:
		return
		
	SmeltingPanel.visible = true
	smelt_slot_container.sync_with_inventory()
	
	if block_reference:
		SmeltingPanel.furnace_in_use = block_reference
		block_reference.load_furnace_data()
	


func _on_mouse_entered() -> void:
	player.can_build = false


func _on_mouse_exited() -> void:
	player.can_build = true
