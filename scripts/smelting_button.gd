extends Button

@onready var SmeltingPanel = get_tree().get_root().find_child("SmeltingPanel", true, false)

func _on_pressed() -> void:
	SmeltingPanel.visible = true
