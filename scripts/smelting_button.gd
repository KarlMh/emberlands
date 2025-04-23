extends Button

@onready var SmeltingPanel = get_tree().get_root().find_child("SmeltingPanel", true, false)
@onready var RecyclingPanel = get_tree().get_root().find_child("RecyclingPanel", true, false)
@onready var smelt_slot_container = get_tree().get_root().find_child("smelt_slot_container", true, false)
@onready var recycle_slot_container = get_tree().get_root().find_child("recycle_slot_container", true, false)
@onready var player_id = multiplayer.get_unique_id()
@onready var player = get_tree().get_root().find_child("Player_" + str(player_id), true, false)
@onready var inventory_slot = get_tree().get_root().find_child("inventory_slot", true, false)
@onready var inventory_window = get_tree().get_root().find_child("inventory_window", true, false)
@onready var options = get_tree().get_root().find_child("options", true, false)

var block_reference = null

func _on_pressed() -> void:
	if inventory_window.visible or options.visible:
		return
	
	player.interactive_button = self
		
	if block_reference:
		if block_reference.get_interaction_type() == "smelt":
			SmeltingPanel.visible = true
			smelt_slot_container.sync_with_inventory()
		
			SmeltingPanel.furnace_in_use = block_reference
			block_reference.load_furnace_data()	
			
		elif block_reference.get_interaction_type() == "recycle":
			RecyclingPanel.visible = true
			recycle_slot_container.sync_with_inventory()
			
			RecyclingPanel.recycler_in_use = block_reference
			block_reference.load_recycler_data()
			print("Recycler in use:", RecyclingPanel.recycler_in_use)

			
			
	


func _on_mouse_entered() -> void:
	player.can_build = false


func _on_mouse_exited() -> void:
	player.can_build = true
