extends Panel

@export var lobbyInfo : PackedScene
signal JoinLobby(id)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func InstanceLobbyInfo(name, userCount):
	var currentInfo = lobbyInfo.instantiate()
	currentInfo.get_node("LobbyName").text = name
	currentInfo.get_node("UserCount").text = userCount
	$VBoxContainer.add_child(currentInfo)
	currentInfo.get_node("Button").connect("button_down", on_Lobby_Button_Down.bind(name))

func on_Lobby_Button_Down(name):
	JoinLobby.emit(name)
