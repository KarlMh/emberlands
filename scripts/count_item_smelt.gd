extends LineEdit

var count = 0
var value_entered: bool
var last_slot

@onready var inventory_slots = get_tree().get_root().find_child("inventory_slots", true, false)

func _ready() -> void:
	self.visible = false


func _on_text_submitted(new_text: String) -> void:
	count = new_text
	value_entered = true
	self.text = "0"
	


	# Call the _gui_input method from the referenced script and pass the event
	if last_slot:
		if int(count) > 0:
			last_slot.smelt()
		self.visible = false
		last_slot = null
