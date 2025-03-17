extends Control

var messages = []
@onready var player = get_tree().get_root().find_child("player", true, false)

var SPEED = 200.0
var JUMP_VELOCITY = -400.0

var chat_toggled_on: bool

var scroll_on_chat: bool

func _ready():
	# Connect signals
	$ChatInput.connect("text_changed", Callable(self, "_on_line_edit_text_changed"))
	$ChatInput.connect("input_action", Callable(self, "_on_line_edit_input_action"))
	$ScrollContainer.scroll_vertical = $ScrollContainer.get_v_scroll_bar().max_value

func _on_line_edit_input_action(_line_edit, _action):
	if _action == "ui_accept":
		send_message()

func send_message():
	var message = $ChatInput.get_text()
	if message != "":
		add_message(message)
		$ChatInput.clear()

func add_message(message):
	messages.append(message)
	var text = ""
	for msg in messages:
		text += "\n" + msg
	$ScrollContainer/TextEdit.set_text(text)
	var line_count = $ScrollContainer/TextEdit.get_line_count()
	await get_tree().create_timer(0.0001).timeout
	$ScrollContainer.scroll_vertical = $ScrollContainer.get_v_scroll_bar().max_value

func _on_chat_input_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		player.SPEED = 0
		player.JUMP_VELOCITY = 0
	else:
		player.SPEED = SPEED
		player.JUMP_VELOCITY = JUMP_VELOCITY
		
	chat_toggled_on = toggled_on

func _on_chat_input_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		send_message()







func _on_text_edit_mouse_entered() -> void:
	scroll_on_chat = true


func _on_text_edit_mouse_exited() -> void:
	scroll_on_chat = false


func _on_text_edit_text_changed() -> void:
	pass
