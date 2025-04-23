extends RichTextLabel

@export var player: CharacterBody2D

func _ready() -> void:
	while not player:
		await get_tree().process_frame
	self.bbcode_text = "[center]" + player.name + "[/center]"
