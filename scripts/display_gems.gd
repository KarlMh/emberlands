extends Control

@onready var player_id = multiplayer.get_unique_id()
@onready var player = get_tree().get_root().find_child("Player_" + str(player_id), true, false)
@onready var gems_label = $Label

func _ready():
	update_gems_display()

func update_gems_display():
	if player:
		gems_label.text = str(player.player_gems)

func _process(_delta):
	update_gems_display()  # Constantly update the display
