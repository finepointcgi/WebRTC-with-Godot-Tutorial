extends Node
enum Message{
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	checkIn,
	serverLobbyInfo,
	removeLobby, 
	reg,
	login
}
var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
var dao : DAO = DAO.new()
var Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
@export var hostPort = 8915
var cryptoUtil : UserCrypto = UserCrypto.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	if "--server" in OS.get_cmdline_args():
		print("hosting on " + str(hostPort))
		peer.create_server(hostPort)
		
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message == Message.lobby:
				JoinLobby(data)
				
			if data.message == Message.offer || data.message == Message.answer || data.message == Message.candidate:
				print("source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
				
			if data.message == Message.removeLobby:
				if lobbies.has(data.lobbyID):
					lobbies.erase(data.lobbyID)

			if data.message == Message.reg:
				reg(data)
			if data.message == Message.login:
				login(data)
	
	pass

func reg(data):
	create_or_update_user(data.userid, data.password)

func login(data):
	if authenticate_user(data.userid, data.password):
		var returnData = dao.get_user_data_from_database(data.userid)
		print(returnData)
		users[data.peerID] = {
			"id" : returnData.id,
			"message" : Message.login,
			"peerID" : data.peerID,
			"rating" : returnData.rating,
			"score" : returnData.score,
			"win" : returnData.win,
			"loss" : returnData.loss,
		}
		peer.get_peer(data.peerID).put_packet(JSON.stringify(users[data.peerID]).to_utf8_buffer())
	else:
		print('false')

func peer_connected(id):
	print("Peer Connected: " + str(id))
	var data = {
		"id" : id,
		"message" : Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(data).to_utf8_buffer())
	pass
	
func peer_disconnected(id):
	users.erase(id)
	pass

func JoinLobby(user):
	var result = ""
	if user.lobbyValue == "":
		user.lobbyValue = generateRandomString()
		lobbies[user.lobbyValue] = Lobby.new(user.id)
		print(user.lobbyValue)
	var player = lobbies[user.lobbyValue].AddPlayer(user.id, user.name)
	
	for p in lobbies[user.lobbyValue].Players:
		
		var data = {
			"message" : Message.userConnected,
			"id" : user.id
		}
		sendToPlayer(p, data)
		
		var data2 = {
			"message" : Message.userConnected,
			"id" : p
		}
		sendToPlayer(user.id, data2)
		
		var lobbyInfo = {
			"message" : Message.lobby,
			"players" : JSON.stringify(lobbies[user.lobbyValue].Players),
			"host" : lobbies[user.lobbyValue].HostID,
			"lobbyValue" : user.lobbyValue
		}
		sendToPlayer(p, lobbyInfo)
		
		
	
	var data = {
		"message" : Message.userConnected,
		"id" : user.id,
		"host" : lobbies[user.lobbyValue].HostID,
		"player" : lobbies[user.lobbyValue].Players[user.id],
		"lobbyValue" : user.lobbyValue
	}
	
	sendToPlayer(user.id, data)
	
func authenticate_user(username, password):
	# Retrieve user's `salt` and `hashed_password` from the database
	var user = dao.get_user_from_database(username)
	var hashed_password = cryptoUtil.hash_password(password, user.salt)
	return hashed_password == user.hashed_password

func create_or_update_user(username, password):
	var salt = cryptoUtil.generate_salt()
	var hashed_password = cryptoUtil.hash_password(password, salt)
	dao.InsertUserData(username, hashed_password, salt)
	# Store `username`, `hashed_password`, and `salt` in the database

func sendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func generateRandomString():
	var result = ""
	for i in range(32):
		var index = randi() % Characters.length()
		result += Characters[index]
	return result

func startServer():
	var server_certs = load("res://my_server_cas.crt")
	var server_key = load("res://my_server_key.key")
	var server_tls_options = TLSOptions.server(server_key, server_certs)

	peer.create_server(8915, "*", server_tls_options)
	print("Started Server")
	
func _on_start_server_button_down():
	startServer()
	pass # Replace with function body.

func _on_button_2_button_down():
	var message = {
		"message" : Message.id,
		"data" : "test"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.


func _on_create_cert_button_down():
	cryptoUtil.CreateCert()
	pass # Replace with function body.
