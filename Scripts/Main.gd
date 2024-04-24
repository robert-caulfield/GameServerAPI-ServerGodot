extends Node

var lobby_scene = preload("res://Scenes/Lobby.tscn")

func _ready():
	get_tree().set_auto_accept_quit(false)
	$SignInNode.signed_in.connect(_on_sign_in_node_signed_in)

func _on_sign_in_node_signed_in():
	# Lobby node is created on successful authentication
	var lobby = lobby_scene.instantiate()
	add_child(lobby)
