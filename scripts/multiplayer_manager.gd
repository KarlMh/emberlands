extends Node

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@export var world_scene: PackedScene

const PORT = 135
var players = {}
var block_array = []
var bg_array = []
var block_ent = []
var bg_ent = []
var sp = Vector2(100, 100)  # Default spawn position

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_host_pressed() -> void:
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print("Hosting game on port ", PORT)
	generate_world()  # Generate world before spawning player

func _on_join_pressed() -> void:
	peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = peer
	print("Joining game on localhost:", PORT)

func _on_connected_to_server():
	# Only clients execute this
	if not multiplayer.is_server():
		print("Connected to server, requesting world data...")
		rpc_id(1, "request_world_data", multiplayer.get_unique_id())

@rpc("any_peer", "reliable")
func request_world_data(requester_id):
	# Only server executes this
	if multiplayer.is_server():
		print("Sending world data to client ", requester_id)
		rpc_id(requester_id, "receive_world_data", block_array, bg_array, block_ent, bg_ent, sp)

func _on_player_connected(id):
	print("Player connected:", id)
	_spawn_player(id)

func _on_player_disconnected(id):
	print("Player disconnected:", id)
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

func _spawn_player(id):
	var player = player_scene.instantiate()
	player.name = "Player_" + str(id)
	player.player_id = id
	player.set_multiplayer_authority(id)
	player.position = sp
	
	players[id] = player
	get_node("/root").add_child(player)
	
	print("Spawned player ", id, " at position ", sp)

func generate_world():
	# Clear existing world if any
	var old_world = get_node_or_null("/root/World")
	if old_world:
		old_world.queue_free()
	
	# Create new world
	var world_instance = world_scene.instantiate()
	world_instance.name = "World"
	get_tree().root.add_child(world_instance)
	
	await get_tree().process_frame
	
	var blockLayer = world_instance.find_child("blockLayer", true, false)
	if blockLayer:
		var array = blockLayer.generate_world()  
		block_array = array[0]
		bg_array = array[1]
		block_ent = array[2]
		bg_ent = array[3]
		sp = blockLayer.spawn_tile
		
		print("World generated. Spawn at:", sp)
		
		# Spawn host player after world is ready
		if multiplayer.is_server():
			_spawn_player(multiplayer.get_unique_id())

@rpc("reliable")
func receive_world_data(new_block_data, new_bg_data, new_block_ent, new_bg_ent,  new_sp):
	print("Receiving world data...")
	block_array = new_block_data
	bg_array = new_bg_data
	block_ent = new_block_ent
	bg_ent = new_bg_ent
	sp = new_sp
	
	# Clear existing world
	var old_world = get_node_or_null("/root/World")
	if old_world:
		old_world.queue_free()
	
	# Create new world instance
	var world_instance = world_scene.instantiate()
	world_instance.name = "World"
	get_tree().root.add_child(world_instance)
	
	await get_tree().process_frame
	
	# Load received data
	var blockLayer = world_instance.find_child("blockLayer", true, false)
	if blockLayer:
		blockLayer.load_world(block_array, bg_array, block_ent, bg_ent,  sp)
		print(block_ent)
		print("World loaded on client")
		
		# Spawn client player after world is loaded
		_spawn_player(multiplayer.get_unique_id())
		
@rpc("reliable", "any_peer")
func notify_block_break(tile_pos: Vector2i, is_foreground: bool, new_id: int) -> void:
	print("Server received block break request from", multiplayer.get_remote_sender_id())

	if not multiplayer.is_server():
		print("I'm not the server, ignoring.")
		return

	var world = get_node("/root/World")
	var block_layer = world.find_child("blockLayer", true, false)
	var bg_layer = world.find_child("backgroundLayer", true, false)

	if is_foreground and block_layer:
		block_layer.set_cell(tile_pos, new_id)
	elif bg_layer:
		bg_layer.set_cell(tile_pos, new_id)

	print("Block broken at:", tile_pos)
	
	# Sync to all clients (including the sender)
	rpc("sync_block_break", tile_pos, is_foreground, new_id)



@rpc("call_local", "reliable")
func sync_block_break(tile_pos: Vector2i, is_foreground: bool, new_id: int) -> void:
	print("Syncing block break to: ", tile_pos, "as ", new_id)

	var world = get_node("/root/World")
	var block_layer = world.find_child("blockLayer", true, false)
	var bg_layer = world.find_child("backgroundLayer", true, false)
	var breaking_layer = world.find_child("breakingLayer", true, false)

	if is_foreground and block_layer:
		block_layer.set_cell(tile_pos, new_id)
	elif bg_layer:
		bg_layer.set_cell(tile_pos, new_id)
