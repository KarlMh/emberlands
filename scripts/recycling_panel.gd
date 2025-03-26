extends Panel

@onready var player = get_tree().get_root().find_child("player", true, false)
var recycler_in_use


func _ready() -> void:
	visible = false


func _on_mouse_entered() -> void:
	player.can_build = false


func _on_mouse_exited() -> void:
	player.can_build = true
