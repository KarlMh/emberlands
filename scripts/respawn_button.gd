extends Button

@onready var player_id = multiplayer.get_unique_id()
@onready var player = get_tree().get_root().find_child("Player_" + str(player_id), true, false)
@onready var options = get_tree().get_root().find_child("options", true, false)

var can_respawn = true  # Cooldown flag
const RESPAWN_COOLDOWN = 3.0  # Cooldown time in seconds

func _on_pressed() -> void:
	if not can_respawn:
		print("⏳ Respawn is on cooldown!")
		return
	
	can_respawn = false  # Disable respawn button
		
	options.visible = false
	
	player.freeze()
	player.respawn_player()
	player.unfreeze()
	
	# Start cooldown timer
	await get_tree().create_timer(RESPAWN_COOLDOWN).timeout
	can_respawn = true  # Re-enable respawn button
	print("✅ Respawn ready!")
