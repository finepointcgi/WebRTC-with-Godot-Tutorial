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
var id = 0
var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var hostId :int
var lobbyValue = ""
var lobbyInfo = {}
var rating : int
var score : int
var win : int
var loss : int

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	pass # Replace with function body.

func RTCServerConnected():
	print("RTC server connected")

func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message == Message.id:
				id = data.id
				
				connected(id)
				
			if data.message == Message.userConnected:
				#GameManager.Players[data.id] = data.player
				createPeer(data.id)
				
			if data.message == Message.lobby:
				GameManager.Players = JSON.parse_string(data.players)
				hostId = data.host
				lobbyValue = data.lobbyValue
				
			if data.message == Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got Candididate: " + str(data.orgPeer) + " my id is " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			
			if data.message == Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			
			if data.message == Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)
			
			if data.message == Message.login:
				print("success ")
				print(data)
				rating = data.rating
				score = data.score
				win = data.win
				loss = data.loss
			#if data.message == Message.

func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer

#web rtc connection
func createPeer(id):
	if id != self.id :
		var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})
		print("binding id " + str(id) + "my id is " + str(self.id))
		
		peer.session_description_created.connect(self.offerCreated.bind(id))
		peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
		rtcPeer.add_peer(peer, id)
		
		if !hostId == self.id:
			peer.create_offer()
		pass

func offerCreated(type, data, id):
	if !rtcPeer.has_peer(id):
		return
		
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)
	pass
	
func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.offer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.answer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func connectToServer(ip):
	var client_trusted_cas = load("res://my_server_cas.crt")
	var client_tls_options = TLSOptions.client_unsafe(client_trusted_cas)
	peer.create_client("wss://127.0.0.1:8915", client_tls_options)
	print("started client")

func _on_start_client_button_down():
	connectToServer("")
	pass # Replace with function body.

func _on_button_button_down():
	StartGame.rpc()
	pass # Replace with function body.

@rpc("any_peer", "call_local")
func StartGame():
	var message = {
		"message": Message.removeLobby,
		"lobbyID" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	var scene = load("res://Multiplayer Tutorial Source Files/testScene.tscn").instantiate()
	get_tree().root.add_child(scene)

func _on_join_lobby_button_down():
	var message ={
		"id" : id,
		"message" : Message.lobby,
		"name" : "",
		"lobbyValue" : $LineEdit.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.

func _on_create_user_button_down():
	var message ={
		"userid" : "test",
		"message" : Message.reg,
		"password" : "test",
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.

func _on_login_user_button_down():
	var message = {
		"userid" : "test",
		"peerID" : id,
		"message" : Message.login,
		"password" : "test",
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.
